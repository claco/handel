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
        plan tests => 89;
    };

    use_ok('Handel::Constants', qw(:order :checkout :returnas));
    use_ok('Handel::Cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};

my $haslcf;
eval 'use Locale::Currency::Format';
if (!$@) {$haslcf = 1};


eval 'use Test::MockObject 0.07';
if (!$@) {
    my $mock = Test::MockObject->new();

    $mock->fake_module('Handel::Checkout');
    $mock->fake_new('Handel::Checkout');
    $mock->set_series('process',
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR, #&run1
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR, #&run2
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR  #&run3
    );
    $mock->mock(order => sub {
        my ($self, $order) = @_;

        $self->{'order'} = $order if $order;

        return $self->{'order'};
    });
};
use_ok('Handel::Order');
use_ok('Handel::Subclassing::Order');
use_ok('Handel::Subclassing::OrderOnly');
use_ok('Handel::Subclassing::Cart');


## This is a hack, but it works. :-)
&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile       = "t/order_reconcile_$dbsuffix.db";
        my $db           = "dbi:SQLite:dbname=$dbfile";
        my $createcart   = 't/sql/cart_create_table.sql';
        my $createorder  = 't/sql/order_create_table.sql';

        unlink $dbfile;
        executesql($db, $createorder);
        executesql($db, $createcart);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## test for Handel::Exception::Argument where first param is not a hashref,
    ## cart instance, or uuid
    {
        try {
            my $order = $subclass->new({id=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile('1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart key ref is not a HASH
    {
        try {
            my $order = $subclass->new({id=>'76BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile([cart => '1234']);

            fail;
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
            my $order = $subclass->new({id=>'86BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile($fake);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Order when no Handel::Cart matches the search criteria
    {
        try {
            my $order = $subclass->new({id=>'96BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile({id => '1111'});

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Order when Handel::Cart is empty
    {
        try {
            my $cart = Handel::Cart->construct({
                id => '00000000-0000-0000-0000-000000000000'
            });
            my $order = $subclass->new({id=>'16BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile($cart);

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Order when Handel::Cart subclass is empty
    {
        try {
            my $cart = Handel::Subclassing::Cart->construct({
                id => '00000000-0000-0000-0000-000000000000'
            });
            my $order = $subclass->new({id=>'63BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

            $order->reconcile($cart);

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## reconcile an order from a cart object
    {
        my $cart = Handel::Cart->new({id=>'67BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 1.23
        });
        is($cart->count, 1);

        my $order = $subclass->new({id=>'67BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile($cart);

        is($order->count, 1);
        my $orderitem = $order->items(undef, RETURNAS_ITERATOR)->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };


    ## reconcile an order from a cart id
    {
        my $cart = Handel::Cart->new({id=>'99BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 1.23
        });
        is($cart->count, 1);

        my $order = $subclass->new({id=>'99BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile('99BFFD29-8FAD-4200-A22F-E0D80979ADBF');

        is($order->count, 1);
        my $orderitem = $order->items(undef, RETURNAS_ITERATOR)->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };


    ## reconcile an order from a cart searc hash
    {
        my $cart = Handel::Cart->new({id=>'88BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 1.23
        });
        is($cart->count, 1);

        my $order = $subclass->new({id=>'88BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile({id => '88BFFD29-8FAD-4200-A22F-E0D80979ADBF'});

        is($order->count, 1);
        my $orderitem = $order->items(undef, RETURNAS_ITERATOR)->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };
};
