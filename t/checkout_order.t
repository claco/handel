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
        plan tests => 143;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:order));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
};


## throw exception when setting a bogus order class
{
    try {
        local $ENV{'LANG'} = 'en';
        Handel::Checkout->order_class('Funklebean');

        fail('no exception thrown');
    } catch Handel::Exception::Checkout with {
        pass('caught Handel::Exception::Checkout');
        like(shift, qr/could not be loaded/i, 'not loaded in message');
    } otherwise {
        fail('failed to catch Handel::Exception');
    };
};


## unset something altogether
{
    is(Handel::Checkout->order_class, 'Handel::Order', 'order class is set');
    Handel::Checkout->order_class(undef);
    is(Handel::Checkout->order_class, undef, 'order class is unset');
    Handel::Checkout->order_class('Handel::Order');
    is(Handel::Checkout->order_class, 'Handel::Order', 'order class is reset');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Checkout', 'Handel::Order', 1);
&run('Handel::Checkout', 'Handel::Subclassing::Order', 2);
&run('Handel::Checkout', 'Handel::Subclassing::OrderOnly', 3);

sub run {
    my ($subclass, $orderclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;

    $subclass->order_class($orderclass);

    ## test for Handel::Exception::Checkout when no order can be found as a string
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $checkout = $subclass->new;
            $checkout->order('1234');

            fail('no exception thrown');
        } catch Handel::Exception::Checkout with {
            pass('caught checkout exception');
            like(shift, qr/not find an order/i, 'not find order in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## test for Handel::Exception::Chckout when no order is found as hash
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $checkout = $subclass->new({order => '1234'});

            ok(!$checkout->order, 'no order set');

            fail('no exception thrown');
        } catch Handel::Exception::Checkout with {
            pass('caught argument exception');
            like(shift, qr/not find an order/i, 'not find order in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## test for Handel::Exception::Argument where order object is not a Handel::Order object
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $checkout = $subclass->new;
            my $fake = bless {}, 'MyObject::Foo';
            $checkout->order($fake);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not.*Handel::Order/i, 'not order object in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## test for Handel::Exception::Argument where order option object is not a Handel::Order object
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $fake = bless {}, 'MyObject::Foo';
            my $checkout = $subclass->new({order => $fake});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not.*Handel::Order/i, 'not order object in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## assign the order using a uuid
    {
        my $checkout = $subclass->new;

        $checkout->order('11111111-1111-1111-1111-111111111111');

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($order->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($order->type, ORDER_TYPE_TEMP, 'got temp type');
        is($order->count, 2, 'has 2 items');
    };


    ## assign the order using a uuid as new option
    {
        my $checkout = $subclass->new({order => '11111111-1111-1111-1111-111111111111'});
        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($order->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($order->type, ORDER_TYPE_TEMP, 'got temp type');
        is($order->count, 2, 'has 2 items');
    };


    ## assign the order using a search hash
    {
        my $checkout = $subclass->new;

        $checkout->order({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        });

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($order->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($order->type, ORDER_TYPE_TEMP, 'got temp type');
        is($order->count, 2, 'has 2 items');
    };


    ## assign the order using a search hash as a new option
    {
        my $checkout = $subclass->new({ order => {
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP}
        });

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($order->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($order->type, ORDER_TYPE_TEMP, 'got temp type');
        is($order->count, 2, 'has 2 items');
    };


    ## assign the order using a Handel::Order object
    {
        my $order = $orderclass->search({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        })->first;
        my $checkout = $subclass->new;

        $checkout->order($order);

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($loadedorder->type, ORDER_TYPE_TEMP, 'got temp type');
        is($loadedorder->count, 2, 'has 2 items');
    };


    ## assign the order using a Handel::Order object as a new option
    {
        my $order = $orderclass->search({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        })->first;
        my $checkout = $subclass->new({order => $order});

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111', 'got order id');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($loadedorder->type, ORDER_TYPE_TEMP, 'got temp type');
        is($loadedorder->count, 2, 'has 2 items');
    };

};
