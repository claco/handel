#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
};

ok(!constraint_quantity(-12),       'negative quantity');
ok(!constraint_quantity(0),         'zero quantity');
ok(!constraint_quantity('abc'),     'alpha quantity');
ok(!constraint_quantity('123abc'),  'alphanumeric quantity');
ok(constraint_quantity('1'),        'numeric string quantity');
ok(constraint_quantity(1),          'numeric quantity');
