#!perl -wT
# $Id: constraints_cart_type.t 4 2004-12-28 03:01:15Z claco $
use Test::More tests => 7;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Constants', qw(:cart));
};

ok(!constraint_cart_type('junk.foo'),   'alpha gibberish type');
ok(!constraint_cart_type(-14),          'negative number type');
ok(!constraint_cart_type(23),           'out of range type');
ok(constraint_cart_type(CART_TYPE_SAVED),   'cart type saved');
ok(constraint_cart_type(CART_TYPE_TEMP),    'cart type temp');
