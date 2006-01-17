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
        plan tests => 199;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## This is a hack, but it works. :-)
&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/checkout_cart_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
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
            my $checkout = Handel::Checkout->new;

            $checkout->cart('1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart option is not a hashref
    {
        try {
            my $checkout = Handel::Checkout->new({cart => '1234'});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart object is not a Handel::Cart object
    {
        try {
            my $checkout = Handel::Checkout->new;
            my $fake = bless {}, 'MyObject::Foo';
            $checkout->cart($fake);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart option object is not a Handel::Cart object
    {
        try {
            my $fake = bless {}, 'MyObject::Foo';
            my $checkout = Handel::Checkout->new({cart => $fake});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    {
        ## create and order from a cart id
        my $cart = $subclass->new({id=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF', name=>'My First Cart'});
        my $item = $cart->add({
            id => '5A8E0C3D-92C3-49b1-A988-585C792B7529',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new;
        $checkout->cart($cart->id);

        my $order = $checkout->order;
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
        ## create and order from a cart id object as new option
        my $cart = $subclass->new({id=>'7B029717-08CC-414d-B3EA-680A5B8BC12C', name=>'My First Cart'});
        my $item = $cart->add({
            id => 'AF8F39D9-D958-4ddf-A688-433DB4B62835',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new({cart => $cart->id});

        my $order = $checkout->order;
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
        ## create and order from a Handel::Cart object
        my $cart = $subclass->new({id=>'989935CD-5131-4f50-9D6A-F2192468A817', name=>'My First Cart'});
        my $item = $cart->add({
            id => 'A262096F-E4A7-4c1b-8BAC-01114C68F8FA',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new;
        $checkout->cart($cart);

        my $order = $checkout->order;
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
        ## create and order from a Handel::Cart object as new option
        my $cart = $subclass->new({id=>'A16A5F16-840D-42d2-B414-39E745326552', name=>'My First Cart'});
        my $item = $cart->add({
            id => '91F44BE8-F4DD-47e5-859F-884160B96A0B',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new({cart => $cart});

        my $order = $checkout->order;
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
        ## create and order from a HASH filter
        my $cart = $subclass->new({id=>'D8FD6757-4D8C-4b60-A1AA-AD9D4270480B', name=>'My First Cart'});
        my $item = $cart->add({
            id => '67F4056F-8AC1-4810-96E2-57E1A5BE5DE3',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new;
        $checkout->cart({id=>'D8FD6757-4D8C-4b60-A1AA-AD9D4270480B', name=>'My First Cart'});

        my $order = $checkout->order;
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
        ## create and order from a HASH filter as a new option
        my $cart = $subclass->new({id=>'255EE4F0-8CB0-42ed-8853-94AB47BDF14E', name=>'My First Cart'});
        my $item = $cart->add({
            id => 'D399FE0A-87A0-4162-B552-6F161D671684',
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $checkout = Handel::Checkout->new({cart => {id=>'255EE4F0-8CB0-42ed-8853-94AB47BDF14E', name=>'My First Cart'}});

        my $order = $checkout->order;
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

};
