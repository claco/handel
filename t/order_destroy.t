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
        plan tests => 37;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order :returnas));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/order_destroy_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/order_create_table.sql';
        my $data    = 't/sql/order_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## Test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            $subclass->destroy(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## Destroy a single order via instance
    {
        my $order = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, 1);
        is($order->subtotal, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        $order->destroy;

        my $reorder = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });

        is($reorder, 0);
    };


    ## Destroy multiple orders with wildcard filter
    {
        my $orders = $subclass->load({billtofirstname => 'Chris%'}, RETURNAS_ITERATOR);
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 2);

        $subclass->destroy({
            billtofirstname => 'Chris%'
        });

        $orders = $subclass->load({billtofirstname => 'Chris%'}, RETURNAS_ITERATOR);
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 0);
    };

};
