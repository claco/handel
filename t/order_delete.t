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
        plan tests => 22;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Constants', ':order');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/order_delete.db';
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
        Handel::Order->delete(id => '1234');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Delete a single order item contents and validate counts
{
    my $order = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($order, 'Handel::Order');
    is($order->count, 1);
    is($order->subtotal, 0);

    is($order->delete({sku => 'SKU3333'}), 1);
    is($order->count, 0);
    is($order->subtotal, 0);

    my $reorder = Handel::Order->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($reorder, 'Handel::Order');
    is($reorder->count, 0);
    is($reorder->subtotal, 0);
};


## Delete multiple order item contents with wildcard filter and validate counts
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    is($order->count, 2);
    is($order->subtotal, 0);

    ok($order->delete({sku => 'SKU%'}));
    is($order->count, 0);
    is($order->subtotal, 0);

    my $reorder = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($reorder, 'Handel::Order');
    is($reorder->count, 0);
    is($reorder->subtotal, 0);
};