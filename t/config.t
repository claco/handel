#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::ConfigReader');
};

my $cfg = Handel::ConfigReader->new();
isa_ok($cfg, 'Handel::ConfigReader');

{
    local $ENV{'MySetting'} = 23;
    ok(exists $cfg->{'MySetting'});
    is($cfg->get('MySetting'), $ENV{'MySetting'});
    is($cfg->get('MyOtherSetting', 25), 25);

    ok(!exists $cfg->{'JunkSetting'});
};


## test defaults and their way through get/tied hash
{
    local $Handel::ConfigReader::Defaults{'MyDefault'} = 'Default';

    ok(exists $cfg->{'MyDefault'});
    is($cfg->get('MyDefault'), 'Default');
    is($cfg->{'MyDefault'}, 'Default');
};