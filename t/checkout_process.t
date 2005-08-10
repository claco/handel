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
        plan tests => 26;
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

        fail;
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

        fail;
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


## Run a successful test pipeline
{
    my $order = Handel::Order->new({});
        $order->add({
            sku      => 'SKU1',
            quantity => 1,
            price    => 1.11
        });
        $order->add({
            sku      => 'SKU2',
            quantity => 2,
            price    => 2.22
        });

    my $checkout = Handel::Checkout->new({
        pluginpaths => 'Handel::TestPipeline',
        loadplugins => 'Handel::TestPipeline::InitializeTotals',
        phases      => CHECKOUT_ALL_PHASES,
        order       => $order
    });

    is($checkout->process, CHECKOUT_STATUS_OK);

    my $items = $order->items;
    is($order->subtotal, 5.55);
    is($items->first->total, 1.11);
    is($items->next->total, 4.44);

    my @messages = $checkout->messages;
    is(scalar @messages, 0);
};


## Run a failing test pipeline
{
    my $order = Handel::Order->new({
        billtofirstname => 'BillToFirstName',
        billtolastname  => 'BillToLastName'
    });
        $order->add({
            sku      => 'SKU1',
            quantity => 1,
            price    => 1.11
        });
        $order->add({
            sku      => 'SKU2',
            quantity => 2,
            price    => 2.22
        });

    my $checkout = Handel::Checkout->new({
        pluginpaths => 'Handel::TestPipeline',
        loadplugins => ['Handel::TestPipeline::InitializeTotals',
                        'Handel::TestPipeline::ValidateError'
                       ],
        phases      => CHECKOUT_ALL_PHASES,
        order       => $order
    });

    is($checkout->process, CHECKOUT_STATUS_ERROR);

    is($checkout->order->billtofirstname, 'BillToFirstName');
    is($checkout->order->billtolastname, 'BillToLastName');

    my $items = $order->items;
    is($order->subtotal, 0);
    is($items->first->sku, 'SKU1');
    is($items->next->sku, 'SKU2');

    my @messages = $checkout->messages;
    is(scalar @messages, 1);
    ok($messages[0] =~ /ValidateError/);
};