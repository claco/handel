#!perl -wT
# $Id$
use strict;
use warnings;
require Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql comp_to_file);

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
    'Apache::Test 1.16 not installed') if $@;

eval 'use DBD::SQLite';
Test::More::plan(skip_all =>
    'DBD::SQLite not installed') if $@;

## test new/add first so we can use them to test everything else
my @tests = (
    'cart_new.xsp',
    'cart_new_filtered.xsp',
    'cart_new_and_add.xsp',
    'cart_new_and_add_filtered.xsp',
    'cart_cart.xsp',
    'cart_cart_add.xsp',
    'cart_cart_add_filtered.xsp',
    'cart_cart_clear.xsp',
    'cart_cart_delete.xsp',
    'cart_cart_delete_filtered.xsp',
    'cart_cart_filtered.xsp',
    'cart_cart_filtered_no_results.xsp',
    'cart_cart_item.xsp',
    'cart_cart_item_filtered.xsp',
    'cart_cart_item_filtered_no_results.xsp',
    'cart_cart_item_update.xsp',
    'cart_cart_items.xsp',
    'cart_cart_items_filtered.xsp',
    'cart_cart_items_filtered_no_results.xsp',
    'cart_cart_items_update.xsp',
    'cart_cart_no_results.xsp',
    'cart_cart_save.xsp',
    'cart_cart_update.xsp',
    'cart_carts.xsp',
    'cart_carts_add.xsp',
    'cart_carts_add_filtered.xsp',
    'cart_carts_clear.xsp',
    'cart_carts_delete.xsp',
    'cart_carts_delete_filtered.xsp',
    'cart_carts_filtered.xsp',
    'cart_carts_filtered_no_results.xsp',
    'cart_carts_item.xsp',
    'cart_carts_item_filtered.xsp',
    'cart_carts_item_filtered_no_results.xsp',
    'cart_carts_item_update.xsp',
    'cart_carts_items.xsp',
    'cart_carts_items_filtered.xsp',
    'cart_carts_items_filtered_no_results.xsp',
    'cart_carts_items_update.xsp',
    'cart_carts_no_results.xsp',
    'cart_carts_save.xsp',
    'cart_carts_update.xsp',
);

use Apache::TestUtil;
Apache::TestRequest->import(qw(GET));
Apache::Test::plan(tests => (scalar @tests * 1),
    need('AxKit', 'mod_perl', need_apache(1), need_lwp())
);

my $docroot = Apache::Test::vars('documentroot');

## Setup SQLite DB for tests
{

    my $dbfile  = "$docroot/cart.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);
};

foreach (@tests) {
    my $r = GET($_);

    ok($r->code == 200);

    my ($ok, $response, $file) = comp_to_file($r->content, "$docroot/out/$_.out");

    t_debug("HTTP Status: " . $r->code);
    t_debug("Received:\n", $response);
    t_debug("Expected:\n", $file);

    ok($ok);
};