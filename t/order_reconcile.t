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
        plan tests => 122;
    };

    use_ok('Handel::Constants', qw(:order :checkout));
    use_ok('Handel::Cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};

my $haslcf;
eval 'use Locale::Currency::Format';
if (!$@) {$haslcf = 1};


eval 'use Test::MockObject 1.07';
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
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->clear_schema($schema);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref,
    ## cart instance, or uuid
    ## this test has changed. constraint_uuid was canned to be more custom
    ## schema friendly
    {
        try {
            my $order = $subclass->create({
                id=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

            $order->reconcile('1234');

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart key ref is not a HASH
    {
        try {
            my $order = $subclass->create({
                id=>'76BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'76BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

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
            my $order = $subclass->create({
                id=>'86BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'86BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

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
            my $order = $subclass->create({
                id=>'96BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'96BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

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
            my $cart = Handel::Cart->create({
                id => '00000000-0000-0000-0000-00000000000'.$dbsuffix,
                shopper => '00000000-0000-0000-0000-00000000000'.$dbsuffix
            });
            my $order = $subclass->create({
                id=>'16BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'16BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

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
            my $cart = Handel::Subclassing::Cart->search({
                id => '00000000-0000-0000-0000-00000000000'.$dbsuffix
            })->first;
            my $order = $subclass->create({
                id=>'63BFFD29-8FAD-4200-A22F-E0D80979ADBF',
                shopper=>'63BFFD29-8FAD-4200-A22F-E0D80979ADBF'
            });

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
        my $cart = Handel::Cart->create({shopper=>'67BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 1.23
        });
        is($cart->count, 1);

        my $order = $subclass->create({shopper=>'67BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile($cart);

        is($order->count, 1);
        my $orderitem = $order->items()->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };


    ## reconcile an order from a cart id
    {
        my $cart = Handel::Cart->create({shopper=>'99BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 1.23
        });
        is($cart->count, 1);

        my $order = $subclass->create({shopper=>'99BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile($cart->id);

        is($order->count, 1);
        my $orderitem = $order->items()->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };


    ## reconcile an order from a cart search hash
    {
        my $cart = Handel::Cart->create({shopper=>'88BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        my $item = $cart->add({
            sku => 'SKU123',
            quantity => 1,
            price => 2.00
        });
        is($cart->count, 1);

        my $order = $subclass->create({shopper=>'88BFFD29-8FAD-4200-A22F-E0D80979ADBF'});
        is($order->count, 0);
        $order->reconcile({id => $cart->id});

        is($order->count, 1);
        my $orderitem = $order->items()->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);


        ## reconcile again , which should leave things unchanged
        $order->reconcile({id => $cart->id});
        is($order->count, 1);
        $orderitem = $order->items()->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);


        ## reconcile with same subtotal, different count
        $item->price(1.00);
        $cart->add({
            sku => 'SKU1234',
            quantity => 1,
            price => 1.00
        });
        is($cart->count, 2);
        $order->reconcile({id => $cart->id});
        is($order->count, 2);
        $orderitem = $order->items()->first;
        is($item->sku, $orderitem->sku);
        is($item->quantity, $orderitem->quantity);
        is($item->price, $orderitem->price);
        is($item->total, $orderitem->total);
    };
};
