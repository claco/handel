#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::ConfigReader');
};

my $cfg = Handel::ConfigReader->new();
isa_ok($cfg, 'Handel::ConfigReader');

{
    local $ENV{'MySetting'} = 23;
    is($cfg->get('MySetting'), $ENV{'MySetting'});
    is($cfg->get('MyOtherSetting', 25), 25);
};
