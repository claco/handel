#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::DBI');
};

my $filter   = {foo => 'bar'};
my $wildcard = {foo => 'bar%'};

ok(! Handel::DBI::has_wildcard($filter));
ok(Handel::DBI::has_wildcard($wildcard));

SKIP: {
    eval 'require UUID;';
    eval 'require Data::UUID;' if $@;
    skip 'UUID/Data::UUID not installed', 1 if $@;

    ok(Handel::DBI::uuid);
};
