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
        plan tests => 251;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');

    local $ENV{'LANGUAGE'} = 'en';

    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    {
        no strict 'refs';
        push @{"$subclass\:\:ISA"}, 'Handel::Compat' unless $subclass->isa('Handel::Compat');
        push @{"itemclass\:\:ISA"}, 'Handel::Compat' unless $itemclass->isa('Handel::Compat');
        $subclass->storage->currency_class('Handel::Compat::Currency');
        $itemclass->storage->currency_class('Handel::Compat::Currency');
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $order = $subclass->load(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## load a single cart returning a Handel::Cart object
    {
        my $order = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
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
        my $iterator = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        }, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all orders for the shopper returning a Handel::Iterator object
    {
        my $iterator = $subclass->load({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all carts into an array without a filter on RETURNAS_AUTO
    {
        my @orders = $subclass->load();
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


    ## load all orders into an array without a filter on RETURNAS_LIST
    {
        my @orders = $subclass->load(undef, RETURNAS_LIST);
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
        my @orders = $subclass->load({
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
        my @orders = $subclass->load({
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


    ## load returns 0
    {
        my $order = $subclass->load({
            id => 'notfound'
        });
        is($order, 0);
    };

};
