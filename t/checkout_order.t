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
        plan tests => 38;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/checkout_order.db';
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
        my $checkout = Handel::Checkout->new;

        $checkout->order('1234');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where order option is not a hashref
{
    try {
        my $checkout = Handel::Checkout->new({order => '1234'});

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where order object is not a Handel::Order object
{
    try {
        my $checkout = Handel::Checkout->new;
        my $fake = bless {}, 'MyObject::Foo';
        $checkout->order($fake);

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where order option object is not a Handel::Order object
{
    try {
        my $fake = bless {}, 'MyObject::Foo';
        my $checkout = Handel::Checkout->new({order => $fake});

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## assign the order using a uuid
{
    my $checkout = Handel::Checkout->new;

    $checkout->order('11111111-1111-1111-1111-111111111111');

    my $order = $checkout->order;
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);
};


## assign the order using a uuid as new option
{
    my $checkout = Handel::Checkout->new({order => '11111111-1111-1111-1111-111111111111'});
    my $order = $checkout->order;
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);
};


## assign the order using a search hash
{
    my $checkout = Handel::Checkout->new;

    $checkout->order({
        id => '11111111-1111-1111-1111-111111111111',
        type => ORDER_TYPE_TEMP
    });

    my $order = $checkout->order;
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);
};


## assign the order using a search hash as a new option
{
    my $checkout = Handel::Checkout->new({ order => {
        id => '11111111-1111-1111-1111-111111111111',
        type => ORDER_TYPE_TEMP}
    });

    my $order = $checkout->order;
    isa_ok($order, 'Handel::Order');
    is($order->id, '11111111-1111-1111-1111-111111111111');
    is($order->shopper, '11111111-1111-1111-1111-111111111111');
    is($order->type, ORDER_TYPE_TEMP);
    is($order->count, 2);
};


## assign the order using a Handel::Order object
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111',
        type => ORDER_TYPE_TEMP
    });
    my $checkout = Handel::Checkout->new;

    $checkout->order($order);

    my $loadedorder = $checkout->order;
    isa_ok($loadedorder, 'Handel::Order');
    is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
    is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
    is($loadedorder->type, ORDER_TYPE_TEMP);
    is($loadedorder->count, 2);
};


## assign the order using a Handel::Order object as a new option
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111',
        type => ORDER_TYPE_TEMP
    });
    my $checkout = Handel::Checkout->new({order => $order});

    my $loadedorder = $checkout->order;
    isa_ok($loadedorder, 'Handel::Order');
    is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
    is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
    is($loadedorder->type, ORDER_TYPE_TEMP);
    is($loadedorder->count, 2);
};