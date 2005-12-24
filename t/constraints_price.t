#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
};

ok(!constraint_price('junk.foo'),   'alpha gibberish price');
ok(!constraint_price(-14),          'negative number price');
ok(!constraint_price(-25.79),       'negative float price');
ok(constraint_price(0),             'zero price');
ok(constraint_price(0.00),          'zero float price');
ok(!constraint_price(345.345),      'overextended price float');
ok(!constraint_price(1234567.00),   'overextended price float');
ok(!constraint_price(1234567),      'overextended price int');
ok(constraint_price(25),            'positive int price');
ok(constraint_price(25.89),         'positive float price');
ok(constraint_price(100.00),        'positive float price');
ok(constraint_price(99999.99),      'positive float price');
ok(constraint_price('34.66'),       'positive float price string');
