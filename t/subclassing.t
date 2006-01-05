#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    plan skip_all => 'DBD::SQLite not installed' if($@);

    eval 'use Class::DBI 3.0.8';
    plan skip_all => 'Class::DBI 3.0.8 or greater required' if($@);

    plan tests => 68;

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
{
    my $dbfile      = 't/subclassing.db';
    my $db          = "dbi:SQLite:dbname=$dbfile";
    my $createcart  = 't/sql/cart_create_table.sql';
    my $datacart    = 't/sql/cart_fake_data.sql';
    my $createorder = 't/sql/order_create_table.sql';
    my $dataorder   = 't/sql/order_fake_data.sql';

    unlink $dbfile;
    executesql($db, $createcart);
    executesql($db, $createorder);
    executesql($db, $datacart);
    executesql($db, $dataorder);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## Create a custom cart that still returns Handel::Cart::Item
{
    my $cart = Handel::Subclassing::CartOnly->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($cart, 'Handel::Subclassing::CartOnly');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom');

    my $item = $cart->add({
        sku => 'SKU123'
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item');
    ok(!$item->can('custom'));
};


## Create a custom cart that still returns custom items
{
    my $cart = Handel::Subclassing::Cart->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($cart, 'Handel::Subclassing::Cart');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom');

    my $item = $cart->add({
        sku    => 'SKU123',
        custom => 'custom'
    });

    isa_ok($item, 'Handel::Cart::Item');
    isa_ok($item, 'Handel::Subclassing::CartItem');
    is(ref $item, 'Handel::Subclassing::CartItem');
    can_ok($item, 'custom');
    is($cart->custom, 'custom');
};


## Make sure the old stuff works like normal
{
    my $cart = Handel::Cart->new({
        id => Handel->newuuid
    });

    isa_ok($cart, 'Handel::Cart');
    ok(!$cart->can('custom'));

    my $item = $cart->add({
        sku    => 'SKU123'
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item');
    ok(!$item->can('custom'));
};


## Create a custom order that still returns Handel::Order::Item
{
    my $order = Handel::Subclassing::OrderOnly->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($order, 'Handel::Subclassing::OrderOnly');
    isa_ok($order, 'Handel::Order');
    can_ok($order, 'custom');
    is($order->custom, 'custom');

    my $item = $order->add({
        sku => 'SKU123'
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item');
    ok(!$item->can('custom'));
};


## Create a custom order that still returns custom items
{
    my $order = Handel::Subclassing::Order->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($order, 'Handel::Subclassing::Order');
    isa_ok($order, 'Handel::Order');
    can_ok($order, 'custom');
    is($order->custom, 'custom');

    my $item = $order->add({
        sku    => 'SKU123',
        custom => 'custom'
    });

    isa_ok($item, 'Handel::Order::Item');
    isa_ok($item, 'Handel::Subclassing::OrderItem');
    is(ref $item, 'Handel::Subclassing::OrderItem');
    can_ok($item, 'custom');
    is($order->custom, 'custom');
};


## Make sure the old stuff works like normal
{
    my $order = Handel::Order->new({
        id => Handel->newuuid
    });

    isa_ok($order, 'Handel::Order');
    ok(!$order->can('custom'));

    my $item = $order->add({
        sku    => 'SKU123'
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item');
    ok(!$item->can('custom'));
};


## Load an order after setting order_class
{
    my $checkout = Handel::Subclassing::Checkout->new({
        order => '11111111-1111-1111-1111-111111111111'
    });

    isa_ok($checkout, 'Handel::Subclassing::Checkout');
    isa_ok($checkout, 'Handel::Checkout');
    isa_ok($checkout->order, 'Handel::Subclassing::Order');
    isa_ok($checkout->order, 'Handel::Order');
    is(ref $checkout->order, 'Handel::Subclassing::Order');
};


## Load an order from a cart after setting cart_class using using a uuid
{
    my $order = Handel::Subclassing::OrderCart->new({
        cart => '11111111-1111-1111-1111-111111111111'
    });

    isa_ok($order, 'Handel::Subclassing::OrderCart');
    isa_ok($order, 'Handel::Order');

    is($Handel::Subclassing::OrdersCart::Loads, 1);

    my $item = $order->add({
        sku => 'SKU123'
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item');
    ok(!$item->can('custom'));
};


## Load an order from a cart after setting cart_class using using a hash
{
    my $order = Handel::Subclassing::OrderCart->new({
        cart => {id => '11111111-1111-1111-1111-111111111111'}
    });

    isa_ok($order, 'Handel::Subclassing::OrderCart');
    isa_ok($order, 'Handel::Order');

    is($Handel::Subclassing::OrdersCart::Loads, 2);

    my $item = $order->add({
        sku => 'SKU123'
    });

    isa_ok($item, 'Handel::Order::Item');
    is(ref $item, 'Handel::Order::Item');
    ok(!$item->can('custom'));
};
