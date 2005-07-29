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
        plan tests =>8;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Constants', ':order');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/order_clear.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/order_create_table.sql';
    my $data    = 't/sql/order_fake_data.sql';

    unlink $dbfile;
    executesql($db, $create);
    executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## Clear order contents and validate counts
{
    my $order = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($order, 'Handel::Order');
    ok($order->count >= 1);

    $order->clear;
    is($order->count, 0);

    my $reorder = Handel::Order->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($reorder, 'Handel::Order');

    is($reorder->count, 0);
};