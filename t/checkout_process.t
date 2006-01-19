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
        plan tests => 92;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout', 1);
&run('Handel::Subclassing::Checkout', 2);
&run('Handel::Subclassing::CheckoutStash', 3);

sub run {
    my ($subclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/checkout_process_$dbsuffix.db";
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
            my $checkout = $subclass->new;

            $checkout->process;

            fail;
        } catch Handel::Exception::Checkout with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument when phases is not array reference
    ## or string
    {
        try {
            my $checkout = $subclass->new;
            $checkout->process({'1234' => 1});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## load test plugins and checkout setup/teardown
    {
        my $checkout = $subclass->new({
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

        my $checkout = $subclass->new({
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

        my $checkout = $subclass->new({
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


    ## Check stash writes and lifetime
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

        my $checkout = $subclass->new({
            pluginpaths => 'Handel::TestPipeline',
            loadplugins => ['Handel::TestPipeline::WriteToStash',
                            'Handel::TestPipeline::ReadFromStash'],
            phases      => CHECKOUT_ALL_PHASES,
            order       => $order
        });

        is($checkout->process, CHECKOUT_STATUS_OK);
        is($checkout->stash->{'WriteToStash'}, 'WrittenToStash');

        my %plugins = map { ref $_ => $_ } $checkout->plugins;
        is(scalar keys %plugins, 2);
        ok(exists $plugins{'Handel::TestPipeline::ReadFromStash'});
        is($plugins{'Handel::TestPipeline::ReadFromStash'}->{'ReadFromStash'}, 'WrittenToStash');

        my @messages = $checkout->messages;
        is(scalar @messages, 0);
    };

};
