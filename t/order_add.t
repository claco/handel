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
        plan tests => 66;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Order::Item');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constants', ':order');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/order_add.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/order_create_table.sql';
    my $data    = 't/sql/order_fake_data.sql';

    unlink $dbfile;
    executesql($db, $create);
    executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## test for Handel::Exception::Argument where first param is not a hashref
## or Handle::Order::Item subclass
{
    try {
        my $newitem = Handel::Order->add(id => '1234');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where first param is not a hashref
## or Handle::Order::Item subclass
{
    try {
        my $fakeitem = bless {}, 'FakeItem';
        my $newitem = Handel::Order->add($fakeitem);

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## add a new item by passing a hashref
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');

    my $item = $order->add({
        sku         => 'SKU9999',
        quantity    => 2,
        price       => 1.11,
        total       => 2.22,
        description => 'Line Item SKU 9'
    });
    isa_ok($item, 'Handel::Order::Item');
    is($item->orderid, $order->id);
    is($item->sku, 'SKU9999');
    is($item->quantity, 2);
    is($item->price, 1.11);
    is($item->description, 'Line Item SKU 9');
    is($item->total, 2.22);

    is($order->count, 3);
    is($order->subtotal, 5.55);

    my $reorder = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($reorder, 'Handel::Order');
    is($reorder->count, 3);

    my $reitem = $reorder->items({sku => 'SKU9999'});
    isa_ok($reitem, 'Handel::Order::Item');
    is($reitem->orderid, $reorder->id);
    is($reitem->sku, 'SKU9999');
    is($reitem->quantity, 2);
    is($reitem->price, 1.11);
    is($reitem->description, 'Line Item SKU 9');
    is($reitem->total, 2.22);
};


## add a new item by passing a Handel::Order::Item
{
    my $newitem = Handel::Order::Item->new({
        sku         => 'SKU8888',
        quantity    => 1,
        price       => 1.11,
        description => 'Line Item SKU 8',
        total       => 2.22
    });
    isa_ok($newitem, 'Handel::Order::Item');

    my $order = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($order, 'Handel::Order');

    my $item = $order->add($newitem);
    isa_ok($item, 'Handel::Order::Item');
    is($item->orderid, $order->id);
    is($item->sku, 'SKU8888');
    is($item->quantity, 1);
    is($item->price, 1.11);
    is($item->description, 'Line Item SKU 8');
    is($item->total, 2.22);

    is($order->count, 2);
    is($order->subtotal, 5.55);

    my $reorder = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($reorder, 'Handel::Order');
    is($reorder->count, 2);

    my $reitem = $order->items({sku => 'SKU8888'});
    isa_ok($reitem, 'Handel::Order::Item');
    is($reitem->orderid, $reorder->id);
    is($reitem->sku, 'SKU8888');
    is($reitem->quantity, 1);
    is($reitem->price, 1.11);
    is($reitem->description, 'Line Item SKU 8');
    is($reitem->total, 2.22);
};


## add a new item by passing a Handel::Cart::Item
{
    my $newitem = Handel::Cart::Item->new({
        sku         => 'SKU9999',
        quantity    => 2,
        price       => 1.11,
        description => 'Line Item SKU 9'
    });
    isa_ok($newitem, 'Handel::Cart::Item');

    my $order = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($order, 'Handel::Order');

    my $item = $order->add($newitem);
    isa_ok($item, 'Handel::Order::Item');
    is($item->orderid, $order->id);
    is($item->sku, 'SKU9999');
    is($item->quantity, 2);
    is($item->price, 1.11);
    is($item->description, 'Line Item SKU 9');
    is($item->total, 2.22);

    is($order->count, 3);
    is($order->subtotal, 5.55);

    my $reorder = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($reorder, 'Handel::Order');
    is($reorder->count, 3);

    my $reitem = $order->items({sku => 'SKU9999'});
    isa_ok($reitem, 'Handel::Order::Item');
    is($reitem->orderid, $reorder->id);
    is($reitem->sku, 'SKU9999');
    is($reitem->quantity, 2);
    is($reitem->price, 1.11);
    is($reitem->description, 'Line Item SKU 9');
    is($reitem->total, 2.22);
};