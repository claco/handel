#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 81;
    };

    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/order_items.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/order_create_table.sql';
    my $data    = 't/sql/order_fake_data.sql';

    unlink $dbfile;
    executesql($db, $create);
    executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## load multiple item Handel::Order object and get items array on RETURNAS_AUTO
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my @items = $order->items;
    is(scalar @items, $order->count);

    my $item1 = $items[0];
    isa_ok($item1, 'Handel::Order::Item');
    is($item1->id, '11111111-1111-1111-1111-111111111111');
    is($item1->orderid, $order->id);
    is($item1->sku, 'SKU1111');
    is($item1->quantity, 1);
    is($item1->price, 1.11);
    is($item1->description, 'Line Item SKU 1');

    my $item2 = $items[1];
    isa_ok($item2, 'Handel::Order::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->orderid, $order->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
};


## load multiple item Handel::Order object and get items array on RETURNAS_LIST
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type,ORDER_TYPE_TEMP);
    is($order->count, 2);

    my @items = $order->items(undef, RETURNAS_LIST);
    is(scalar @items, $order->count);

    my $item1 = $items[0];
    isa_ok($item1, 'Handel::Order::Item');
    is($item1->id, '11111111-1111-1111-1111-111111111111');
    is($item1->orderid, $order->id);
    is($item1->sku, 'SKU1111');
    is($item1->quantity, 1);
    is($item1->price, 1.11);
    is($item1->description, 'Line Item SKU 1');

    my $item2 = $items[1];
    isa_ok($item2, 'Handel::Order::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->orderid, $order->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
};


## load multiple item Handel::Order object and get items Iterator
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my $items = $order->items;
    isa_ok($items, 'Handel::Iterator');
    is($items->count, 2);
};


## load multiple item Handel::Order object and get filter single item
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my $item2 = $order->items({sku => 'SKU2222'});
    isa_ok($item2, 'Handel::Order::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->orderid, $order->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
};


## load multiple item Handel::Order object and get filter single item to Iterator
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my $iterator = $order->items({sku => 'SKU2222'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
};


## load multiple item Handel::Order object and get wilcard filter to Iterator
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my $iterator = $order->items({sku => 'SKU%'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
    is($iterator, 2);
};


## load multiple item Handel::Order object and get filter bogus item to Iterator
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);

    my $iterator = $order->items({sku => 'notfound'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
};
