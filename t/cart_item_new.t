#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 10;

    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};

## test for Handel::Exception::Argument where first param is not a hashref
{
    try {
        my $item = Handel::Cart::Item->new(sku => 'FOO');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## create a new cart item object
{
    my $item = Handel::Cart::Item->new({
        sku         => 'sku1234',
        price       => 1.23,
        quantity    => 2,
        description => 'My SKU'
    });
    isa_ok($item, 'Handel::Cart::Item');
    ok(constraint_uuid($item->id));
    is($item->price, 1.23);
    is($item->quantity, 2);
    is($item->description, 'My SKU');
    is($item->total, 2.46);
};
