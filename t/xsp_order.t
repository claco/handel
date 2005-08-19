#!perl -wT
# $Id$
use strict;
use warnings;
require Test::More;
use lib 't/lib';
use Handel::TestHelper qw(preparetables comp_to_file);

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
    'Apache::Test 1.16 not installed') if $@;

eval 'use DBD::SQLite';
Test::More::plan(skip_all =>
    'DBD::SQLite not installed') if $@;

## test new/add first so we can use them to test everything else
my @tests = (
    'order_new.xsp',
    'order_new_filtered.xsp',
    'order_new_and_add.xsp',
    'order_new_and_add_filtered.xsp',
    'order_order.xsp',
    'order_order_add.xsp',
    'order_order_add_filtered.xsp',
    'order_order_clear.xsp',
    'order_order_delete.xsp',
    'order_order_delete_filtered.xsp',
    'order_order_filtered.xsp',
    'order_order_filtered_no_results.xsp',
    'order_order_item.xsp',
    'order_order_item_filtered.xsp',
    'order_order_item_filtered_no_results.xsp',
    'order_order_item_update.xsp',
    'order_order_items.xsp',
    'order_order_items_filtered.xsp',
    'order_order_items_filtered_no_results.xsp',
    'order_order_items_update.xsp',
    'order_order_no_results.xsp',
    'order_order_update.xsp',
    'order_orders.xsp',
    'order_orders_add.xsp',
    'order_orders_add_filtered.xsp',
    'order_orders_clear.xsp',
    'order_orders_delete.xsp',
    'order_orders_delete_filtered.xsp',
    'order_orders_filtered.xsp',
    'order_orders_filtered_no_results.xsp',
    'order_orders_item.xsp',
    'order_orders_item_filtered.xsp',
    'order_orders_item_filtered_no_results.xsp',
    'order_orders_item_update.xsp',
    'order_orders_items.xsp',
    'order_orders_items_filtered.xsp',
    'order_orders_items_filtered_no_results.xsp',
    'order_orders_items_update.xsp',
    'order_orders_no_results.xsp',
    'order_orders_update.xsp',
    'order_new_minimal.xsp',
    'order_new_no_results_trigger.xsp',
    'order_currency_format.xsp',
);

require Apache::TestUtil;
Apache::TestUtil->import(qw(t_debug));
Apache::TestRequest->import(qw(GET));
Apache::Test::plan(tests => ((scalar @tests * 2) + 3),
    need('AxKit', 'mod_perl', need_apache(1), need_lwp())
);

my $docroot = Apache::Test::vars('documentroot');

## Setup SQLite DB for tests
{
    my $dbfile  = "$docroot/xsp.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";

    preparetables($db, [qw(cart order)]);
    preparetables($db, ['cart'], 1);
};

my $r = GET('/axkit/order_uuid.xsp');
ok($r->code == 200);
ok($r->content =~ /(<p>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}<\/p>){2}/i);

LOOP: foreach (@tests) {
    my $r = GET("/axkit/$_");

    ok($r->code == 200);

    my ($ok, $response, $file) = comp_to_file($r->content, "$docroot/axkit/out/$_.out");

    t_debug($_);
    t_debug("HTTP Status: " . $r->code);
    t_debug("Expected:\n", $file);
    t_debug("Received:\n", $response);

    ## This is a hack, but hey, it's just one test right?
    if ($_ =~ /currency/) {
        SKIP: {
            eval 'use Locale::Currency::Format';
            Apache::Test::skip('Locale::Currency::Format not installed', 2) if $@;
            next LOOP if $@;
        };
    };

    ok($ok);
};

my $c = GET('/axkit/order_currency_convert.xsp');
ok($c->code == 200);
t_debug($c->content);
