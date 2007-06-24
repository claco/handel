#!perl -wT
# $Id$
## no critic (ProhibitPackageVars)
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 29;
    use Scalar::Util qw/refaddr/;

    local $ENV{'MOD_PERL_API_VERSION'} = 100;

    use_ok('Handel::ConfigReader');
    use_ok('Handel');
    use_ok('Handel::Exception', ':try');
};

my $cfg = Handel::ConfigReader->new();
isa_ok($cfg, 'Handel::ConfigReader');


## MOD_PERL_API_VERSION was bogus, but set
is($Handel::ConfigReader::MOD_PERL, 0, 'MOD_PERL should be zero');


## get a setting from ENV
{
    local $ENV{'MySetting'} = 23;
    ok(exists $cfg->{'MySetting'}, 'MySetting exists in ENV');
    is($cfg->get('MySetting'), 23, 'MySetting is 23');
    is($cfg->get('MyOtherSetting', 25), 25, 'Return default when nothing exists');

    ok(!exists $cfg->{'JunkSetting'}, 'Bogus setting does not exist');
};


## test defaults and their way through get/tied hash
{
    local $Handel::ConfigReader::DEFAULTS{'MyDefault'} = 'Default';

    ok(exists $cfg->{'MyDefault'}, 'MyDefault exists');
    is($cfg->get('MyDefault'), 'Default', 'get MyDefault returns default from %Defaults');
    is($cfg->{'MyDefault'}, 'Default', 'MyDefault returns default from %Defaults');
};


## setting tied hash key does nothing to config value
{
    local $ENV{'MySetting'} = 23;
    is($cfg->{'MySetting'}, 23, 'MySetting is 23');
    $cfg->{'MySetting'} = 24;
    is($cfg->{'MySetting'}, 23, 'MySetting is still 23');
};


## deleting tied hash key does nothing to config value
{
    local $ENV{'MySetting'} = 23;
    is($cfg->{'MySetting'}, 23, 'MySetting is 23');
    delete $cfg->{'MySetting'};
    is($cfg->{'MySetting'}, 23, 'MySetting is still 23');
};


## clearing tied hash key does nothing to config value
{
    local $ENV{'MySetting'} = 23;
    is($cfg->{'MySetting'}, 23, 'MySetting is 23');
    %{$cfg} = ();
    is($cfg->{'MySetting'}, 23, 'MySetting is still 23');
};


## send a ref through the werks
{
    local %Handel::ConfigReader::DEFAULTS = ('MP1DefaultRef' => {});
    isa_ok($cfg->{'MP1DefaultRef'}, 'HASH', 'return ref passed through defaults');
};


## return undef if new doesn't
{
    no warnings 'redefine';
    local *Handel::ConfigReader::new = sub {undef};

    is(Handel::ConfigReader->instance, undef, 'no new returns undef');
};


## get the same instance
{
    my $instance1 = Handel::ConfigReader->instance;
    my $instance2 = Handel::ConfigReader->instance;
    isa_ok($instance1, 'Handel::ConfigReader');
    isa_ok($instance2, 'Handel::ConfigReader');
    is(refaddr $instance1, refaddr $instance2, 'instance returns the same instance');
};


## throw exception when setting bogus config class
{
    try {
        local $ENV{'LANG'} = 'en';
        Handel->config_class('Bogus');

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/could not be loaded/i, 'class not loaded in exception message');
        is(Handel->config_class, 'Handel::ConfigReader', 'config class is still set');
    } otherwise {
        fail('Other exception thrown');
    };
};


# get the config reader
{
    my $config = Handel->config;
    isa_ok($config, 'Handel::ConfigReader');

    my $reconfig = Handel->config;
    isa_ok($reconfig, 'Handel::ConfigReader');

    is(refaddr $config, refaddr $reconfig, 'config returns same instance');
};
