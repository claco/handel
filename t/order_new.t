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
        plan tests => 50;
    };

    use_ok('Handel::Constants', qw(:order :checkout :returnas));
    use_ok('Handel::Cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};

eval 'use Test::MockObject 0.07';
if (!$@) {
    my $mock = Test::MockObject->new();

    $mock->fake_module('Handel::Checkout');
    $mock->fake_new('Handel::Checkout');
    $mock->mock(process => sub {
        my ($self, $order) = @_;
        $self->{'order'} = $order;

        return &CHECKOUT_STATUS_OK;
    });
    $mock->mock(order => sub {
        my $self = shift;

        return $self->{'order'};
    });
};
use_ok('Handel::Order');


## Setup SQLite DB for tests
{
    my $dbfile       = 't/order_new.db';
    my $db           = "dbi:SQLite:dbname=$dbfile";
    my $createcart   = 't/sql/cart_create_table.sql';
    my $createorder  = 't/sql/order_create_table.sql';

    unlink $dbfile;
    executesql($db, $createorder);
    executesql($db, $createcart);

    local $^W = 0;
    Handel::DBI->connection($db);
};

## test for Handel::Exception::Argument where first param is not a hashref
{
    try {
        my $order = Handel::Order->new(id => '1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where cart key scalar is not a uuid
{
    try {
        my $order = Handel::Order->new({cart => '1234'});
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where cart key is not a Handel::Cart object
{
    try {
        my $fake = bless {}, 'MyObject::Foo';
        my $order = Handel::Order->new({cart => $fake});
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Order when no Handel::Cart matches the search criteria
{
    try {
        my $order = Handel::Order->new({cart => {id => '1111'}});
    } catch Handel::Exception::Order with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Order when Handel::Cart is empty
{
    try {
        my $cart = Handel::Cart->construct({});

        my $order = Handel::Order->new({cart => $cart});
    } catch Handel::Exception::Order with {
        pass;
    } otherwise {
        fail;
    };
};

SKIP: {
    eval 'use Test::MockObject 0.07';
    skip 'Test::MockObject not installed', 40 if $@;

    {
        ## create and order from a Handel::Cart object
        my $cart = Handel::Cart->new({id=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF', name=>'My First Cart'});
        my $item = $cart->add({
            id => '5A8E0C3D-92C3-49b1-A988-585C792B7529',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $order = Handel::Order->new({cart => $cart});
        isa_ok($order, 'Handel::Order');
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items;
        isa_ok($orderitem, 'Handel::Order::Item');
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    {
        ## create and order from a search hash
        my $cart = Handel::Cart->new({id=>'F00F8DE0-A39C-41e4-A906-D43DF55D93D8', name=>'My Other Second Cart'});
        my $item = $cart->add({
            id => 'B1247A21-E121-470e-AA97-245B7BD7CD19',
            sku => 'sku2',
            quantity => 3,
            price => 2.22,
            description => 'My Second Item'
        });

        my $order = Handel::Order->new({cart => {id => 'F00F8DE0-A39C-41e4-A906-D43DF55D93D8'}});
        isa_ok($order, 'Handel::Order');
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items;
        isa_ok($orderitem, 'Handel::Order::Item');
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    {
        ## create and order from a cart id
        my $cart = Handel::Cart->new({id=>'99BE4783-2A16-4172-A5A8-415A7D984BCA', name=>'My Other Third Cart'});
        my $item = $cart->add({
            id => '699E1E68-0DCE-43d5-A747-F380769DDCF0',
            sku => 'sku3',
            quantity => 2,
            price => 1.23,
            description => 'My Third Item'
        });

        my $order = Handel::Order->new({cart => '99BE4783-2A16-4172-A5A8-415A7D984BCA'});
        isa_ok($order, 'Handel::Order');
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items;
        isa_ok($orderitem, 'Handel::Order::Item');
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    ## check that when multiple carts are found that we only load the first one
    {
        my $order = Handel::Order->new({cart => {name => '%Other%'}});
        isa_ok($order, 'Handel::Order');
        is($order->count, 1);
        is($order->subtotal, 6.66);

        my $orderitem = $order->items;
        isa_ok($orderitem, 'Handel::Order::Item');
        is($orderitem->sku, 'sku2');
        is($orderitem->quantity, 3);
        is($orderitem->price, 2.22);
        is($orderitem->description, 'My Second Item');
        is($orderitem->total, 6.66);
        is($orderitem->orderid, $order->id);
    };
};