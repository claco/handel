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
        plan tests => 18;
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


## test for Handel::Exception::Argument where cart key is not a hashref
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
    skip 'Test::MockObject not installed', 9 if $@;

    my $cart = Handel::Cart->new({id=>'11111111-1111-1111-1111-111111111111', name=>'MyCart'});
    my $item = $cart->add({
        id => '22222222-2222-2222-2222-222222222222',
        sku => 'sku1',
        quantity => 2,
        price => 1.11,
        description => 'My Item'
    });

    my $order = Handel::Order->new({cart => $cart});
    isa_ok($order, 'Handel::Order');
    is($cart->count, $order->count);

    my $orderitem = $order->items;
    isa_ok($orderitem, 'Handel::Order::Item');
    is($orderitem->sku, $item->sku);
    is($orderitem->quantity, $item->quantity);
    is($orderitem->price, $item->price);
    is($orderitem->description, $item->description);
    is($orderitem->total, $item->total);
    is($orderitem->orderid, $order->id);
};