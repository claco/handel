#!perl -wT
# $Id$
## no critic (ProhibitPackageVars, ProhibitStringyEval, RequireCarping)
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    local $ENV{'MOD_PERL_API_VERSION'} = 2;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 10;

        my $request = Test::MockObject->new;
        $request->set_series('dir_config', 'MP2RequestHere', undef);

        my $server = Test::MockObject->new;
        $server->set_series('dir_config', 'MP2ServerHere', undef);

        my @requests = (undef, $request, undef, $request);
        my @servers = (undef, $server, $server, $server, $server);

        Test::MockObject->fake_module('Apache2::RequestRec');
        Test::MockObject->fake_module('Apache2::RequestIO');
        Test::MockObject->fake_module('Apache2::RequestUtil' => (
            request => sub {shift @requests}
        ));
        Test::MockObject->fake_module('Apache2::ServerUtil' => (
            server  => sub {shift @servers || die 'Boom'}
        ));
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::ConfigReader');
};

my $cfg = Handel::ConfigReader->new;
isa_ok($cfg, 'Handel::ConfigReader');
is($Handel::ConfigReader::MOD_PERL, 2, 'mod_perl 2.0 detected');


## return undef if no request/server objects exist
is($cfg->{'MP2Setting'}, undef, 'no request/server returns undef');


## return dir_config from request
is($cfg->{'MP2Setting'}, 'MP2RequestHere', 'return request dir_config first');


## return dir_config from server if no request
is($cfg->{'MP2Setting'}, 'MP2ServerHere', 'return server dir_config next');


## return from ENV if dir_config spits out nothing
{
    local $ENV{'MP2ENVSetting'} = 'MMP2ENVHere';
    is($cfg->{'MP2ENVSetting'}, 'MMP2ENVHere', 'return from ENV on empty dir_config');
};


## return ENV if dir_config crashes
{
    local $ENV{'MP2ENVSetting'} = 'MMP2ENVCrash';
    is($cfg->{'MP2ENVSetting'}, 'MMP2ENVCrash', 'return from ENV on crashed dir_config');
};


## return from defaults if all else fails
{
    local %Handel::ConfigReader::DEFAULTS = ('MP2Default' => 'MP2DefaultHere');
    is($cfg->{'MP2Default'}, 'MP2DefaultHere', 'return from defaults on empty dir_config and ENV');
};


## return undef when dir_config, ENV and defaults fail
{
    local %Handel::ConfigReader::DEFAULTS = ('MP2Default' => undef);
    is($cfg->{'MP2Default'}, undef, 'return undef when dir_config, ENV and defaults fail');
};
