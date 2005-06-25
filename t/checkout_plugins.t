#!perl -wT
# $Id$
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 56;

BEGIN {
    use_ok('Handel::Checkout');
};

SKIP: {
    eval 'use Module::Pluggable 2.8';
    skip 'Module::Pluggable >= 2.9 not installed', 55 if $@;

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
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
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
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
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
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
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
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
        };
    };
};