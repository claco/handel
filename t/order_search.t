#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 370;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(no_populate => 1, db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $order = $subclass->search(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## throw exception when options isn't a hashref
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->search({id => '1234'}, []);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'not a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## test order_by option
    {
        my @orders = $subclass->search(undef, {order_by => 'id DESC'});
        is(scalar @orders, 3);
        is($orders[0]->id, '33333333-3333-3333-3333-333333333333', 'last order is first');
        is($orders[1]->id, '22222222-2222-2222-2222-222222222222', 'middle order is middle');
        is($orders[2]->id, '11111111-1111-1111-1111-111111111111', 'first order is last');
    };


    ## load a single cart returning a Handel::Cart object
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };
    };


    ## load a single cart returning a Handel::Object object on an instance
    {
        my $instance = bless {}, $subclass;
        my $it = $instance->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };
    };


    ## load a single order returning a Handel::Iterator object
    {
        my $iterator = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all orders for the shopper returning a Handel::Iterator object
    {
        my $iterator = $subclass->search({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all carts into an array without a filter
    {
        my @orders = $subclass->search();
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type,ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array without a filter
    {
        my @orders = $subclass->search();
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array with a filter
    {
        my @orders = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        is(scalar @orders, 1);

        my $order = $orders[0];
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '22222222-2222-2222-2222-222222222222');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_SAVED);
        is($order->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };
    };


    ## load all orders into an array with a wildcard filter
    {
        my @orders = $subclass->search({
            id => '%-%'
        });
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array with SQL::Abstract wildcard filter
    {
        my @orders = $subclass->search({
            id => {like => '%-%'}
        });
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load returns 0
    {
        my $order = $subclass->search({
            id => 'notfound'
        });
        is($order, 0);
    };

};


## pass in storage instead
{
    my $storage = Handel::Order->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    $altschema->resultset('Orders')->create({
        id      => '88888888-8888-8888-8888-888888888888',
        shopper => '88888888-8888-8888-8888-888888888888',
        type    => ORDER_TYPE_SAVED
    });

    my $order = Handel::Order->search({
        id => '88888888-8888-8888-8888-888888888888'
    }, {
        storage => $storage
    })->first;
    isa_ok($order, 'Handel::Order');
    is($order->shopper, '88888888-8888-8888-8888-888888888888');
    is($order->type, ORDER_TYPE_SAVED);
    is($order->count, 0);
    is($order->subtotal+0, 0);
    is(refaddr $order->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('Orders')->search({id => '88888888-8888-8888-8888-888888888888'})->count, 1, 'order found in alt storage');
    is($schema->resultset('Orders')->search({id => '88888888-8888-8888-8888-888888888888'})->count, 0, 'alt order not in class storage');
};
