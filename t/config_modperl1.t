#!perl -wT
# $Id$
## no critic (ProhibitPackageVars, ProhibitStringyEval)
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    local $ENV{'MOD_PERL'} = 1;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 9;

        my $request = Test::MockObject->new;
        $request->set_series('dir_config', 'MP1RequestHere', undef);

        my $server = Test::MockObject->new;
        $server->set_series('dir_config', 'MP1ServerHere', undef);

        my @requests = (undef, $request, undef, $request);
        my @servers = (undef, $server, $server, $server);

        Test::MockObject->fake_module('Apache' => (
            request => sub {shift @requests},
            server  => sub {shift @servers}
        ));
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::ConfigReader');
};

my $cfg = Handel::ConfigReader->new;
isa_ok($cfg, 'Handel::ConfigReader');
is($Handel::ConfigReader::MOD_PERL, 1, 'mod_perl 1.0 detected');


## return undef if no request/server objects exist
is($cfg->{'MP1Setting'}, undef, 'no request/server returns undef');

## return dir_config from request
is($cfg->{'MP1Setting'}, 'MP1RequestHere', 'return request dir_config first');

## return dir_config from server if no request
is($cfg->{'MP1Setting'}, 'MP1ServerHere', 'return server dir_config next');


## return from ENV if dir_config spits out nothing
{
    local $ENV{'MP1ENVSetting'} = 'MMP1ENVHere';
    is($cfg->{'MP1ENVSetting'}, 'MMP1ENVHere', 'return from ENV on empty dir_config');
};


## return from defaults if all else fails
{
    local %Handel::ConfigReader::DEFAULTS = ('MP1Default' => 'MP1DefaultHere');
    is($cfg->{'MP1Default'}, 'MP1DefaultHere', 'return from defaults on empty dir_config and ENV');
};


## return undef when dir_config, ENV and defaults fail
{
    local %Handel::ConfigReader::DEFAULTS = ('MP1Default' => undef);
    is($cfg->{'MP1Default'}, undef, 'return undef when dir_config, ENV and defaults fail');
};
