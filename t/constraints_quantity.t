#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 13;

BEGIN {
    use_ok('Handel::Constraints', ':all');
    use_ok('Handel::Exception', ':try');
};

ok(!constraint_quantity(-12),       'negative quantity');
ok(!constraint_quantity(0),         'zero quantity');
ok(!constraint_quantity('abc'),     'alpha quantity');
ok(!constraint_quantity('123abc'),  'alphanumeric quantity');
ok(constraint_quantity('1'),        'numeric string quantity');
ok(constraint_quantity(1),          'numeric quantity');


## test max quantity failure exception
{
    local $ENV{'HandelMaxQuantity'} = 5;
    local $ENV{'HandelMaxQuantityAction'} = 'Exception';

    ok(constraint_quantity(5),     'quantity <= max');

    try {
        constraint_quantity(6);
    } catch Handel::Exception::Constraint with {
        pass;
    } otherwise {
        fail;
    };
};

## test max quantity adjustment
{
    local $ENV{'HandelMaxQuantity'} = 5;

    ok(constraint_quantity(5),     'quantity <= max');

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(constraint_quantity(7, $object, undef, $hash));
    is($hash->{'quantity'}, 5);
};
