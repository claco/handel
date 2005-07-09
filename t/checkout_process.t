#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    #diag "Waiting on Module::Pluggable 2.9 Taint Fixes";
    eval 'require DBD::SQLite';
    eval 'use Module::Pluggable 2.9';
    if($@) {
        #plan skip_all => 'DBD::SQLite not installed';
        plan skip_all => 'Module::Pluggable 2.9 not installed';
    } else {
        plan tests => 13;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/checkout_new.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $createcart   = 't/sql/cart_create_table.sql';
    my $createorder  = 't/sql/order_create_table.sql';
    my $data    = 't/sql/order_fake_data.sql';

    unlink $dbfile;
    executesql($db, $createorder);
    executesql($db, $createcart);
    executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## test for Handel::Exception::Checkout where no order is loaded
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->process;
    } catch Handel::Exception::Checkout with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument when phases is not array reference
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->process('1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        diag shift;
        fail;
    };
};


## load test plugins and checkout setup/teardown
{
    my $checkout = Handel::Checkout->new({
        order => '11111111-1111-1111-1111-111111111111',
        pluginpaths => 'Handel::TestPlugins, Handel::OtherTestPlugins',
        phases => [CHECKOUT_PHASE_INITIALIZE]
    });

    is($checkout->process, CHECKOUT_STATUS_OK);

    foreach ($checkout->plugins) {
        ok($_->{'setup_called'});
        ok($_->{'handler_called'});
        ok($_->{'teardown_called'});
    };
};
