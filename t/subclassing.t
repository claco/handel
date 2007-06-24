#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 68;
    };

    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Subclassing::CartItem');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Subclassing::OrderItem');
    use_ok('Handel::Subclassing::OrderCart');
    use_ok('Handel::Subclassing::OrdersCart');
};


## Setup SQLite DB for tests
my $schema = Handel::Test->init_schema;
local $ENV{'HandelDBIDSN'} = $schema->dsn;

## Create a custom cart that still returns Handel::Cart::Item
{
    my $cart = Handel::Subclassing::CartOnly->create({
        custom => 'custom',
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($cart, 'Handel::Subclassing::CartOnly');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom', 'got custom field');

    my $item = $cart->add({
        sku => 'SKU123',
        quantity => 1,
        price => 1.11
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item', 'is exactly a Handel::Cart::Item object');
    ok(!$item->can('custom'), 'no custom method');
};


## Create a custom cart that still returns custom items
{
    my $cart = Handel::Subclassing::Cart->create({
        shopper => '00000000-0000-0000-0000-000000000000',
        custom => 'custom'
    });

    isa_ok($cart, 'Handel::Subclassing::Cart');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom', 'got custom field');

    my $item = $cart->add({
        sku    => 'SKU123',
        custom => 'custom',
        quantity => 1,
        price => 1.11
    });

    isa_ok($item, 'Handel::Cart::Item');
    isa_ok($item, 'Handel::Subclassing::CartItem');
    is(ref $item, 'Handel::Subclassing::CartItem', 'is exactly a Handel::Subclassing::CartItem object');
    can_ok($item, 'custom');
    is($cart->custom, 'custom', 'got custom field');
};


## Make sure the old stuff works like normal
{
    my $cart = Handel::Cart->create({
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($cart, 'Handel::Cart');
    ok(!$cart->can('custom'), 'no custom method');

    my $item = $cart->add({
        sku    => 'SKU123',
        quantity => 1,
        price => 1.00
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item', 'is exactly a Handel::Cart::Item object');
    ok(!$item->can('custom'), 'has no custom method');
};


## Create a custom order that still returns Handel::Order::Item
{
    my $order = Handel::Subclassing::OrderOnly->create({
        shopper => '00000000-0000-0000-0000-000000000000',
        custom => 'custom'
    });

    isa_ok($order, 'Handel::Subclassing::OrderOnly');
    isa_ok($order, 'Handel::Order');
    can_ok($order, 'custom');
    is($order->custom, 'custom', 'got custom field');

    my $item = $order->add({
        sku => 'SKU123',
        quantity => 1,
        price => 1.00
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item', 'is exactly a Handel::Order::Item object');
    ok(!$item->can('custom'), 'has no custom method');
};


## Create a custom order that still returns custom items
{
    my $order = Handel::Subclassing::Order->create({
        shopper => '00000000-0000-0000-0000-000000000000',
        custom => 'custom'
    });

    isa_ok($order, 'Handel::Subclassing::Order');
    isa_ok($order, 'Handel::Order');
    can_ok($order, 'custom');
    is($order->custom, 'custom', 'got custom field');

    my $item = $order->add({
        sku    => 'SKU123',
        custom => 'custom',
        quantity => 1,
        price => 1
    });

    isa_ok($item, 'Handel::Order::Item');
    isa_ok($item, 'Handel::Subclassing::OrderItem');
    is(ref $item, 'Handel::Subclassing::OrderItem', 'is exactly a Handel::Subclassing::OrderItem object');
    can_ok($item, 'custom');
    is($order->custom, 'custom', 'got custom field');
};


## Make sure the old stuff works like normal
{
    my $order = Handel::Order->create({
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($order, 'Handel::Order');
    ok(!$order->can('custom'), 'has no custom method');

    my $item = $order->add({
        sku    => 'SKU123',
        quantity => 1,
        price => 1.00
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item', 'is exactly a Handel::Order::Item object');
    ok(!$item->can('custom'), 'has no custom method');
};


## Load an order after setting order_class
{
    my $checkout = Handel::Subclassing::Checkout->new({
        order => '11111111-1111-1111-1111-111111111111',
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($checkout, 'Handel::Subclassing::Checkout');
    isa_ok($checkout, 'Handel::Checkout');
    isa_ok($checkout->order, 'Handel::Subclassing::Order');
    isa_ok($checkout->order, 'Handel::Order');
    is(ref $checkout->order, 'Handel::Subclassing::Order', 'is exactly a Handel::Subclassing::Order object');
};


## Load an order from a cart after setting cart_class using using a uuid
{
    my $order = Handel::Subclassing::OrderCart->create({
        cart => '11111111-1111-1111-1111-111111111111',
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($order, 'Handel::Subclassing::OrderCart');
    isa_ok($order, 'Handel::Order');
    is($Handel::Subclassing::OrdersCart::Searches, 1, 'performed search');

    my $item = $order->add({
        sku => 'SKU123',
        quantity => 1,
        price => 1.00
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item', 'is exactly a Handel::Order::Item object');
    ok(!$item->can('custom'), 'has no custom method');
};

## Load an order from a cart after setting cart_class using using a hash
{
    my $order = Handel::Subclassing::OrderCart->create({
        cart => {id => '11111111-1111-1111-1111-111111111111'},
        shopper => '00000000-0000-0000-0000-000000000000'
    });

    isa_ok($order, 'Handel::Subclassing::OrderCart');
    isa_ok($order, 'Handel::Order');

    is($Handel::Subclassing::OrdersCart::Searches, 2, 'performed search');

    my $item = $order->add({
        sku => 'SKU123',
        quantity => 1,
        price => 1.00
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item', 'is exactly a Handel::Order::Item object');
    ok(!$item->can('custom'), 'has no custom method');
};
