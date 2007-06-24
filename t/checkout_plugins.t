#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 1275;

    use_ok('Handel::Checkout');
    use_ok('Handel::Checkout::Plugin');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Constants', ':checkout');
    use_ok('Handel::Exception', ':try');
};


## make sure no path returns no path
is(Handel::Checkout::_path_to_array(''), '', 'path to array returns nothing for nothing');



## name returns class name, others do nothing
{
    my $plugin = Handel::Checkout::Plugin->new;
    isa_ok($plugin, 'Handel::Checkout::Plugin');
    is($plugin->name, 'Handel::Checkout::Plugin', 'name returns class name');
    is(Handel::Checkout::Plugin->name, 'Handel::Checkout::Plugin', 'name returns class name');
    is(Handel::Checkout::Plugin::name, undef, 'function returns nothing');

    is(Handel::Checkout::Plugin->setup, undef, 'setup does nothing');
    is(Handel::Checkout::Plugin->teardown, undef, 'teardown does nothing');

    {
        my $warning;
        local $SIG{'__WARN__'} = sub {
            $warning = shift;
        };
        is(Handel::Checkout::Plugin->register, undef, 'register does nothing');
        like($warning, qr/plugin .* defined register/i, 'warning was set');
    };
};


## test for exception when adding the same phase, preference
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});
    $checkout->{'plugins'} = [bless {}, 'main'];
    $checkout->add_handler(CHECKOUT_PHASE_INITIALIZE, sub{}, 350);

    try {
        local $ENV{'LANG'} = 'en';
        $checkout->add_handler(CHECKOUT_PHASE_INITIALIZE, sub{}, 350);

        fail('no exception thrown');
    } catch Handel::Exception::Checkout with {
            pass('caught checkout exception');
            like(shift, qr/already a handler/i, 'phase exists in message');
    } otherwise {
        fail('other exception thrown');
    };
};


## This is a hack, but it works. :-)
&run('Handel::Checkout');
&run('Handel::Subclassing::Checkout');
&run('Handel::Subclassing::CheckoutStash');

sub run {
    my ($subclass) = @_;


    ## test for Handel::Exception::Argument on bad add_handler phase
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $checkout = $subclass->new;

            $checkout->add_handler(42, sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not a valid checkout_phase/i, 'phase not found in message');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## test for Handel::Exception::Argument on bad CODE reference
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $checkout = $subclass->new;

            $checkout->add_handler(CHECKOUT_PHASE_INITIALIZE, 'foo');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not a code/i, 'not a code in message');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## Add a custom phase and verify it works in add_handler
    {
        try {
            local $ENV{'LANG'} = 'en';

            #clean out the new constant between subclass runs
            {
                no warnings;
                undef *Handel::Constants::CHECKOUT_PHASE_CUSTOM;
                @Handel::Constants::CHECKOUT_ALL_PHASES = grep { $_ != 99 } @Handel::Constants::CHECKOUT_ALL_PHASES;
            };

            $subclass->add_phase('CHECKOUT_PHASE_CUSTOM', 99);
            my $checkout = $subclass->new;

            $checkout->add_handler(Handel::Constants->CHECKOUT_PHASE_CUSTOM, sub{});

            pass('added custom phase');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## Load all plugins in a new path
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins';

        my $checkout = $subclass->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin exists');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        my $plugin = $plugins{'Handel::TestPlugins::First'};
        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'}, 'init was called');
        ok($plugin->{'register_called'}, 'register was called');

        isa_ok($checkout->{'handlers'}->{1}->{1}->[0], 'Handel::TestPlugins::First');
        is(ref $checkout->{'handlers'}->{1}->{1}->[1], 'CODE', 'stored code ref');
        $checkout->{'handlers'}->{1}->{1}->[1]->($plugin);
        ok($plugin->{'handler_called'}, 'handler called');
    };


    ## Load all plugins in a new path using new option as string
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::TestPlugins'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        my $plugin = $plugins{'Handel::TestPlugins::First'};
        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'}, 'init was called');
        ok($plugin->{'register_called'}, 'register was called');

        isa_ok($checkout->{'handlers'}->{1}->{1}->[0], 'Handel::TestPlugins::First');
        is(ref $checkout->{'handlers'}->{1}->{1}->[1], 'CODE', 'registered code ref');
        $checkout->{'handlers'}->{1}->{1}->[1]->($plugin);
        ok($plugin->{'handler_called'}, 'handler called');
    };


    ## Load all plugins in a new path using new option as array reference
    {
        my $checkout = $subclass->new({pluginpaths => ['Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        my $plugin = $plugins{'Handel::TestPlugins::First'};
        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'}, 'init called');
        ok($plugin->{'init_called'}, 'register called');

        isa_ok($checkout->{'handlers'}->{1}->{1}->[0], 'Handel::TestPlugins::First');
        is(ref $checkout->{'handlers'}->{1}->{1}->[1], 'CODE', 'has code ref');
        $checkout->{'handlers'}->{1}->{1}->[1]->($plugin);
        ok($plugin->{'handler_called'}, 'handler called');
    };


    ## Load all plugins in two new paths; space seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins Handel::OtherTestPlugins';

        my $checkout = $subclass->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in two new paths using new option, space seperated
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::TestPlugins Handel::OtherTestPlugins'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in two new paths using new option, comma seperated
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::TestPlugins, Handel::OtherTestPlugins'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in two new paths using new option, array reference
    {
        my $checkout = $subclass->new({pluginpaths => ['Handel::TestPlugins', 'Handel::OtherTestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in two new paths using new option, array reference
    ## Make sure if ignores ENV setting
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::Checkout::Plugin';

        my $checkout = $subclass->new({pluginpaths => ['Handel::TestPlugins', 'Handel::OtherTestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in two new paths; comma seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins';

        my $checkout = $subclass->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2, 'loaded 2 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in three new paths; comma and space seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins Handel::Checkout::Plugin';

        my $checkout = $subclass->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 3, 'loaded 3 plugins');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in an additional path
    {
        local $ENV{'HandelAddPluginPaths'} = 'Handel::OtherTestPlugins';

        my $checkout = $subclass->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in an additional path using new option as string
    {
        my $checkout = $subclass->new({addpluginpaths => 'Handel::OtherTestPlugins'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in an additional path using new option as array reference
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in an additional path using new option as array reference and ENV setting
    {
        local $ENV{'HandelAddPluginPaths'} = 'Handel::TestPlugins';

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 3, 'loaded at least 3 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in HandelIgnorePlugins
    {
        local $ENV{'HandelIgnorePlugins'} = 'Handel::OtherTestPlugins::Second';

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in HandelIgnorePlugins using array
    {
        local $ENV{'HandelIgnorePlugins'} = ['Handel::OtherTestPlugins::Second'];

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in HandelIgnorePlugins using Regex
    {
        local $ENV{'HandelIgnorePlugins'} = qr/^Handel::OtherTestPlugins::Second$/;

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in ignoreplugins new option as array
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => ['Handel::OtherTestPlugins::Second']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in ignoreplugins new option as string
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => 'Handel::OtherTestPlugins::Second'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load all plugins in multiple paths except for ones in ignoreplugins new option as Regex
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => qr/^Handel::OtherTestPlugins::Second$/});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2, 'loaded at least 2 plugins');
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin loaded');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'first plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in HandelLoadPlugins
    {
        local $ENV{'HandelLoadPlugins'} = 'Handel::OtherTestPlugins::Second';

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'init_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in HandelLoadPlugins using array
    {
        local $ENV{'HandelLoadPlugins'} = ['Handel::OtherTestPlugins::Second'];

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'hase code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in HandelLoadPlugins using Regex
    {
        local $ENV{'HandelLoadPlugins'} = qr/^Handel::OtherTestPlugins::Second$/;

        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'fist plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in the loadplugins new option as array
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => ['Handel::OtherTestPlugins::Second']});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in the loadplugins new option as string
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => 'Handel::OtherTestPlugins::Second'});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in the loadplugins new option as Regex
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => qr/^Handel::OtherTestPlugins::Second$/});
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'}, 'second plugin loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::TestPlugins::First'}, 'first plugin no loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::OtherTestPlugins::Second)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## Load only the plugins listed in the loadplugins new option
    {
        my $checkout = $subclass->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'],
            loadplugins => ['Handel::OtherTestPlugins::Second', 'Handel::TestPlugins::First'],
            ignoreplugins => ['Handel::OtherTestPlugins::Second']
        });
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1, 'loaded 1 plugin');
        ok(exists $plugins{'Handel::TestPlugins::First'}, 'fist plugin loaded');
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'}, 'other plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'}, 'test plugin not loaded');
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'}, 'bogus plugin not loaded');

        foreach (qw(Handel::TestPlugins::First)) {
            my $package = $_;
            my $plugin = $plugins{$package};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'}, 'init called');
            ok($plugin->{'register_called'}, 'register called');

            foreach (values %{$checkout->{'handlers'}->{1}}) {
                if (ref $_->[0] eq $package) {
                    isa_ok($_->[0], $package);
                    is(ref $_->[1], 'CODE', 'has code ref');
                    $_->[1]->($plugin);
                    ok($plugin->{'handler_called'}, 'handler called');

                    last;
                };
            };
        };
    };


    ## load plugins and check list/scalar returns on plugins
    {
        my $checkout = $subclass->new({
            pluginpaths => 'Handel::TestPipeline',
            loadplugins => ['Handel::TestPipeline::WriteToStash',
                            'Handel::TestPipeline::ReadFromStash']
        });

        my @plugins = $checkout->plugins;
        is(scalar @plugins, 2, 'loaded 2 plugins');

        my $plugins = $checkout->plugins;
        isa_ok($plugins, 'ARRAY');
        is(scalar @{$plugins}, 2, 'loaded 2 plugins');
    };
};
