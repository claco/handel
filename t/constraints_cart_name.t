#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 9;

    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Constants', qw(:cart));
};

ok(constraint_cart_name('foo', undef, 'name', {type => CART_TYPE_SAVED}), 'ok if type is CART_TYPE_SAVED and name is defined');
ok(constraint_cart_name('foo', undef, 'name', {type => CART_TYPE_TEMP}), 'ok if type is CART_TYPE_TEMP and name is defined');
ok(constraint_cart_name('foo', undef, 'name', {type => 34}), 'ok if type is unknown and name is defined');
ok(constraint_cart_name('foo', undef, 'name', {}), 'ok if type is unknown and name is defined');
ok(constraint_cart_name('foo'), 'ok if type is nothing and name is defined');
ok(!constraint_cart_name(undef, undef, 'name', {type => CART_TYPE_SAVED}), 'not ok if type is CART_TYPE_SAVED and name is undefined');
ok(!constraint_cart_name('', undef, 'name', {type => CART_TYPE_SAVED}), 'not ok if type is CART_TYPE_SAVED and name is undefined');
