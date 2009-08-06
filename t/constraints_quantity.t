#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 26;

    use_ok('Handel::Constraints', ':all');
    use_ok('Handel::Exception', ':try');
};

ok(!constraint_quantity(undef),     'value is undefined');
ok(!constraint_quantity(''),        'value is empty string');
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
        local $ENV{'LANGUAGE'} = 'en';
        constraint_quantity(6);

        fail('no exception thrown');
    } catch Handel::Exception::Constraint with {
        pass('caught constraint exception');
        like(shift, qr/quantity requested.*greater than.*allowed/i, 'failed constraint in message');
    } otherwise {
        fail('caught other exception');
    };
};

## test max quantity with exception action but no max
{
    local $ENV{'HandelMaxQuantity'} = '';
    local $ENV{'HandelMaxQuantityAction'} = 'Exception';

    ok(constraint_quantity(5),     'quantity <= max');

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(constraint_quantity(7, $object, undef, $hash), 'constraint passes with no max');
    is($hash->{'quantity'}, 2, 'quantity is unchanged');
};

## test max quantity adjustment
{
    local $ENV{'HandelMaxQuantity'} = 5;

    ok(constraint_quantity(5),     'quantity <= max');

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(constraint_quantity(7, $object, undef, $hash), 'quantity adjusted');
    is($hash->{'quantity'}, 5, 'quantity adjusted');
};


## test max quantity adjustment with object but no value
{
    local $ENV{'HandelMaxQuantity'} = 5;
    local $ENV{'HandelMaxQuantityAction'} = 'Adjust';

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(!constraint_quantity(0, $object, undef, $hash), 'constraint fails without value');
    is($hash->{'quantity'}, 2, 'quantity unchanged');
};

## test max quantity adjustment with object and value less than max
{
    local $ENV{'HandelMaxQuantity'} = 5;
    local $ENV{'HandelMaxQuantityAction'} = 'Adjust';

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(constraint_quantity(3, $object, undef, $hash), 'constraint passes less than max');
    is($hash->{'quantity'}, 2, 'quantity unchanged');
};

## test quantity with bogus adjustment type
{
    local $ENV{'HandelMaxQuantity'} = 5;
    local $ENV{'HandelMaxQuantityAction'} = 'Boom';

    ok(constraint_quantity(6), 'ignore max if action is bogus');

    my $hash = {quantity => 2};
    my $object = bless {}, 'Fake';

    ok(constraint_quantity(7, $object, undef, $hash), 'constraint passes wit bogus adjustment type');
    is($hash->{'quantity'}, 2, 'quantity is unchanged');
};
