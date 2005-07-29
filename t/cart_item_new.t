#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 19;

    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};

## test for Handel::Exception::Argument where first param is not a hashref
{
    try {
        my $item = Handel::Cart::Item->new(sku => 'FOO');

        fail;
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
    is($item->sku, 'sku1234');
    is($item->price, 1.23);
    is($item->quantity, 2);
    is($item->description, 'My SKU');
    is($item->total, 2.46);

    eval 'use Locale::Currency::Format';
    if ($@) {
        is($item->price->format, 1.23);
        is($item->price->format('CAD'), 1.23);
        is($item->price->format(undef, 'FMT_NAME'), 1.23);
        is($item->price->format('CAD', 'FMT_NAME'), 1.23);
        is($item->total->format, 2.46);
        is($item->total->format('CAD'), 2.46);
        is($item->total->format(undef, 'FMT_NAME'), 2.46);
        is($item->total->format('CAD', 'FMT_NAME'), 2.46);
    } else {
        is($item->price->format, '1.23 USD');
        is($item->price->format('CAD'), '1.23 CAD');
        is($item->price->format(undef, 'FMT_NAME'), '1.23 US Dollar');
        is($item->price->format('CAD', 'FMT_NAME'), '1.23 Canadian Dollar');
        is($item->total->format, '2.46 USD');
        is($item->total->format('CAD'), '2.46 CAD');
        is($item->total->format(undef, 'FMT_NAME'), '2.46 US Dollar');
        is($item->total->format('CAD', 'FMT_NAME'), '2.46 Canadian Dollar');
    };
};
