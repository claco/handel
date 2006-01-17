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
        plan tests => 126;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout', 'Handel::Order', 1);
&run('Handel::Checkout', 'Handel::Subclassing::Order', 2);
&run('Handel::Checkout', 'Handel::Subclassing::OrderOnly', 3);

sub run {
    my ($subclass, $orderclass, $dbsuffix) = @_;

    $subclass->order_class($orderclass);

    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/checkout_order_$dbsuffix.db";
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
            my $checkout = $subclass->new;

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
            my $checkout = $subclass->new({order => '1234'});

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
            my $checkout = $subclass->new;
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
            my $checkout = $subclass->new({order => $fake});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## assign the order using a uuid
    {
        my $checkout = $subclass->new;

        $checkout->order('11111111-1111-1111-1111-111111111111');

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a uuid as new option
    {
        my $checkout = $subclass->new({order => '11111111-1111-1111-1111-111111111111'});
        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
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
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
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
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a Handel::Order object
    {
        my $order = $orderclass->load({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        });
        my $checkout = $subclass->new;

        $checkout->order($order);

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->type, ORDER_TYPE_TEMP);
        is($loadedorder->count, 2);
    };


    ## assign the order using a Handel::Order object as a new option
    {
        my $order = $orderclass->load({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        });
        my $checkout = $subclass->new({order => $order});

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->type, ORDER_TYPE_TEMP);
        is($loadedorder->count, 2);
    };

};
