#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 9;

    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Constants', qw(:order));
};

ok(!constraint_order_type('junk.foo'),   'alpha gibberish type');
ok(!constraint_order_type(-14),          'negative number type');
ok(!constraint_order_type(23),           'out of range type');
ok(!constraint_order_type(undef),        'undefined value');
ok(!constraint_order_type(''),            'value is empty string');
ok(constraint_order_type(ORDER_TYPE_SAVED),   'order type saved');
ok(constraint_order_type(ORDER_TYPE_TEMP),    'order type temp');
