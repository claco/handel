#!perl -wT
# $Id$
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 419;

BEGIN {
    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', ':checkout');
    use_ok('Handel::Exception', ':try');
};


## test for Handel::Exception::Argument on bad add_handler phase
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->add_handler(42, sub{});

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument on bad CODE reference
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->add_handler(CHECKOUT_PHASE_INITIALIZE, 'foo');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Load all plugins in a new path
{
    local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins';

    my $checkout = Handel::Checkout->new;
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    my $plugin = $plugins{'Handel::TestPlugins::First'};
    isa_ok($plugin, 'Handel::Checkout::Plugin');
    ok($plugin->{'init_called'});
    ok($plugin->{'register_called'});

    isa_ok($checkout->{'handlers'}->{1}->[0]->[0], 'Handel::TestPlugins::First');
    is(ref $checkout->{'handlers'}->{1}->[0]->[1], 'CODE');
    $checkout->{'handlers'}->{1}->[0]->[1]->($plugin);
    ok($plugin->{'handler_called'});
};


## Load all plugins in a new path using new option as string
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::TestPlugins'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    my $plugin = $plugins{'Handel::TestPlugins::First'};
    isa_ok($plugin, 'Handel::Checkout::Plugin');
    ok($plugin->{'init_called'});
    ok($plugin->{'register_called'});

    isa_ok($checkout->{'handlers'}->{1}->[0]->[0], 'Handel::TestPlugins::First');
    is(ref $checkout->{'handlers'}->{1}->[0]->[1], 'CODE');
    $checkout->{'handlers'}->{1}->[0]->[1]->($plugin);
    ok($plugin->{'handler_called'});
};


## Load all plugins in a new path using new option as array reference
{
    my $checkout = Handel::Checkout->new({pluginpaths => ['Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    my $plugin = $plugins{'Handel::TestPlugins::First'};
    isa_ok($plugin, 'Handel::Checkout::Plugin');
    ok($plugin->{'init_called'});
    ok($plugin->{'register_called'});

    isa_ok($checkout->{'handlers'}->{1}->[0]->[0], 'Handel::TestPlugins::First');
    is(ref $checkout->{'handlers'}->{1}->[0]->[1], 'CODE');
    $checkout->{'handlers'}->{1}->[0]->[1]->($plugin);
    ok($plugin->{'handler_called'});
};


## Load all plugins in two new paths; space seperated
{
    local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins Handel::OtherTestPlugins';

    my $checkout = Handel::Checkout->new;
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in two new paths using new option, space seperated
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::TestPlugins Handel::OtherTestPlugins'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in two new paths using new option, comma seperated
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::TestPlugins, Handel::OtherTestPlugins'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in two new paths using new option, array reference
{
    my $checkout = Handel::Checkout->new({pluginpaths => ['Handel::TestPlugins', 'Handel::OtherTestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in two new paths using new option, array reference
## Make sure if ignores ENV setting
{
    local $ENV{'HandelPluginPaths'} = 'Handel::Checkout::Plugin';

    my $checkout = Handel::Checkout->new({pluginpaths => ['Handel::TestPlugins', 'Handel::OtherTestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in two new paths; comma seperated
{
    local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins';

    my $checkout = Handel::Checkout->new;
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 2);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in three new paths; comma and space seperated
{
    local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins Handel::Checkout::Plugin';

    my $checkout = Handel::Checkout->new;
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 3);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in an additional path
{
    local $ENV{'HandelAddPluginPaths'} = 'Handel::OtherTestPlugins';

    my $checkout = Handel::Checkout->new;
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in an additional path using new option as string
{
    my $checkout = Handel::Checkout->new({addpluginpaths => 'Handel::OtherTestPlugins'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in an additional path using new option as array reference
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in an additional path using new option as array reference and ENV setting
{
    local $ENV{'HandelAddPluginPaths'} = 'Handel::TestPlugins';

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 3);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in HandelIgnorePlugins
{
    local $ENV{'HandelIgnorePlugins'} = 'Handel::OtherTestPlugins::Second';

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in HandelIgnorePlugins using array
{
    local $ENV{'HandelIgnorePlugins'} = ['Handel::OtherTestPlugins::Second'];

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in HandelIgnorePlugins using Regex
{
    local $ENV{'HandelIgnorePlugins'} = qr/^Handel::OtherTestPlugins::Second$/;

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in ignoreplugins new option as array
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => ['Handel::OtherTestPlugins::Second']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in ignoreplugins new option as string
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => 'Handel::OtherTestPlugins::Second'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load all plugins in multiple paths except for ones in ignoreplugins new option as Regex
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], ignoreplugins => qr/^Handel::OtherTestPlugins::Second$/});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    ok(scalar keys %plugins >= 2);
    ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::Checkout::Plugin::TestPlugin Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in HandelLoadPlugins
{
    local $ENV{'HandelLoadPlugins'} = 'Handel::OtherTestPlugins::Second';

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in HandelLoadPlugins using array
{
    local $ENV{'HandelLoadPlugins'} = ['Handel::OtherTestPlugins::Second'];

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in HandelLoadPlugins using Regex
{
    local $ENV{'HandelLoadPlugins'} = qr/^Handel::OtherTestPlugins::Second$/;

    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in the loadplugins new option as array
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => ['Handel::OtherTestPlugins::Second']});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in the loadplugins new option as string
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => 'Handel::OtherTestPlugins::Second'});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in the loadplugins new option as Regex
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'], loadplugins => qr/^Handel::OtherTestPlugins::Second$/});
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::OtherTestPlugins::Second)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## Load only the plugins listed in the loadplugins new option
{
    my $checkout = Handel::Checkout->new({addpluginpaths => ['Handel::OtherTestPlugins', 'Handel::TestPlugins'],
        loadplugins => ['Handel::OtherTestPlugins::Second', 'Handel::TestPlugins::First'],
        ignoreplugins => ['Handel::OtherTestPlugins::Second']
    });
    my %plugins = map { ref $_ => $_ } $checkout->plugins;

    is(scalar keys %plugins, 1);
    ok(exists $plugins{'Handel::TestPlugins::First'});
    ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
    ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

    foreach (qw(Handel::TestPlugins::First)) {
        my $package = $_;
        my $plugin = $plugins{$package};

        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        foreach (@{$checkout->{'handlers'}->{1}}) {
            if (ref $_->[0] eq $package) {
                isa_ok($_->[0], $package);
                is(ref $_->[1], 'CODE');
                $_->[1]->($plugin);
                ok($plugin->{'handler_called'});

                last;
            };
        };
    };
};


## load plugins and check list/scalar returns on plugins
{
    my $checkout = Handel::Checkout->new({
        pluginpaths => 'Handel::TestPipeline',
        loadplugins => ['Handel::TestPipeline::WriteToStash',
                        'Handel::TestPipeline::ReadFromStash']
    });

    my @plugins = $checkout->plugins;
    is(scalar @plugins, 2);

    my $plugins = $checkout->plugins;
    isa_ok($plugins, 'ARRAY');
    is(scalar @{$plugins}, 2);
};