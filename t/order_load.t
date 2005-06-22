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

    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/order_load.db';
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
{
    try {
        my $order = Handel::Order->load(id => '1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## load a single cart returning a Handel::Cart object
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);
};


## load a single order returning a Handel::Iterator object
{
    my $iterator = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    }, 1);
    isa_ok($iterator, 'Handel::Iterator');
};


## load all orders for the shopper returning a Handel::Iterator object
{
    my $iterator = Handel::Order->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($iterator, 'Handel::Iterator');
};


## load all carts into an array without a filter on RETURNAS_AUTO
{
    my @orders = Handel::Order->load();
    is(scalar @orders, 3);

    my $order1 = $orders[0];
    isa_ok($order1, 'Handel::Order');
    is($order1->id, '11111111-1111-1111-1111-111111111111');
    is($order1->shopper, '11111111-1111-1111-1111-111111111111');
    is($order1->type,ORDER_TYPE_TEMP);
    is($order1->count, 2);

    my $order2 = $orders[1];
    isa_ok($order2, 'Handel::Order');
    is($order2->id, '22222222-2222-2222-2222-222222222222');
    is($order2->shopper, '11111111-1111-1111-1111-111111111111');
    is($order2->type, ORDER_TYPE_SAVED);
    is($order2->count, 1);

    my $order3 = $orders[2];
    isa_ok($order3, 'Handel::Order');
    is($order3->id, '33333333-3333-3333-3333-333333333333');
    is($order3->shopper, '33333333-3333-3333-3333-333333333333');
    is($order3->type, ORDER_TYPE_SAVED);
    is($order3->count, 2);
};


## load all orders into an array without a filter on RETURNAS_LIST
{
    my @orders = Handel::Order->load(undef, RETURNAS_LIST);
    is(scalar @orders, 3);

    my $order1 = $orders[0];
    isa_ok($order1, 'Handel::Order');
    is($order1->id, '11111111-1111-1111-1111-111111111111');
    is($order1->shopper, '11111111-1111-1111-1111-111111111111');
    is($order1->type, ORDER_TYPE_TEMP);
    is($order1->count, 2);

    my $order2 = $orders[1];
    isa_ok($order2, 'Handel::Order');
    is($order2->id, '22222222-2222-2222-2222-222222222222');
    is($order2->shopper, '11111111-1111-1111-1111-111111111111');
    is($order2->type, ORDER_TYPE_SAVED);
    is($order2->count, 1);

    my $order3 = $orders[2];
    isa_ok($order3, 'Handel::Order');
    is($order3->id, '33333333-3333-3333-3333-333333333333');
    is($order3->shopper, '33333333-3333-3333-3333-333333333333');
    is($order3->type, ORDER_TYPE_SAVED);
    is($order3->count, 2);
};


## load all orders into an array with a filter
{
    my @orders = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    is(scalar @orders, 1);

    my $order = $orders[0];
    isa_ok($order, 'Handel::Order');
    is($order->id, '22222222-2222-2222-2222-222222222222');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_SAVED);
    is($order->count, 1);
};


## load all orders into an array with a wildcard filter
{
    my @orders = Handel::Order->load({
        id => '%-%'
    });
    is(scalar @orders, 3);

    my $order1 = $orders[0];
    isa_ok($order1, 'Handel::Order');
    is($order1->id, '11111111-1111-1111-1111-111111111111');
    is($order1->shopper, '11111111-1111-1111-1111-111111111111');
    is($order1->type, ORDER_TYPE_TEMP);
    is($order1->count, 2);

    my $order2 = $orders[1];
    isa_ok($order2, 'Handel::Order');
    is($order2->id, '22222222-2222-2222-2222-222222222222');
    is($order2->shopper, '11111111-1111-1111-1111-111111111111');
    is($order2->type, ORDER_TYPE_SAVED);
    is($order2->count, 1);

    my $order3 = $orders[2];
    isa_ok($order3, 'Handel::Order');
    is($order3->id, '33333333-3333-3333-3333-333333333333');
    is($order3->shopper, '33333333-3333-3333-3333-333333333333');
    is($order3->type, ORDER_TYPE_SAVED);
    is($order3->count, 2);
};


## load returns 0
{
    my $order = Handel::Order->load({
        id => 'notfound'
    });
    is($order, 0);
};