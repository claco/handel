#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql comp_to_file);

eval 'use Template 2.08';
    plan(skip_all => 'Template 2.08 not installed') if $@;

eval 'use DBD::SQLite';
    plan(skip_all => 'DBD::SQLite not installed') if $@;


## test new/add first so we can use them to test everything else
## convert these to TT2
my @tests = (
#    'cart_new.xsp',
#    'cart_new_filtered.xsp',
#    'cart_new_and_add.xsp',
#    'cart_new_and_add_filtered.xsp',
#    'cart_cart.xsp',
#    'cart_cart_add.xsp',
#    'cart_cart_add_filtered.xsp',
#    'cart_cart_clear.xsp',
#    'cart_cart_delete.xsp',
#    'cart_cart_delete_filtered.xsp',
#    'cart_cart_filtered.xsp',
#    'cart_cart_filtered_no_results.xsp',
#    'cart_cart_item.xsp',
#    'cart_cart_item_filtered.xsp',
#    'cart_cart_item_filtered_no_results.xsp',
#    'cart_cart_item_update.xsp',
#    'cart_cart_items.xsp',
#    'cart_cart_items_filtered.xsp',
#    'cart_cart_items_filtered_no_results.xsp',
#    'cart_cart_items_update.xsp',
#    'cart_cart_no_results.xsp',
#    'cart_cart_save.xsp',
#    'cart_cart_update.xsp',
#    'cart_carts.xsp',
#    'cart_carts_add.xsp',
#    'cart_carts_add_filtered.xsp',
#    'cart_carts_clear.xsp',
#    'cart_carts_delete.xsp',
#    'cart_carts_delete_filtered.xsp',
#    'cart_carts_filtered.xsp',
#    'cart_carts_filtered_no_results.xsp',
#    'cart_carts_item.xsp',
#    'cart_carts_item_filtered.xsp',
#    'cart_carts_item_filtered_no_results.xsp',
#    'cart_carts_item_update.xsp',
#    'cart_carts_items.xsp',
#    'cart_carts_items_filtered.xsp',
#    'cart_carts_items_filtered_no_results.xsp',
#    'cart_carts_items_update.xsp',
#    'cart_carts_no_results.xsp',
#    'cart_carts_save.xsp',
#    'cart_carts_update.xsp',
#    'cart_new_minimal.xsp',
#    'cart_new_no_results_trigger.xsp',
#    'cart_restore_append.xsp',
#    'cart_restore_replace.xsp',
#    'cart_restore_merge.xsp'
);


## Setup SQLite DB for tests
{
    my $dbfile  = "t/htdocs/cart.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    executesql($db, $create);
};

plan(tests => (scalar @tests) + 1);

my $tt      = Template->new() || die 'Error creating Template';
my $docroot = 't/htdocs/tt2';
my $output  = '';

## test uuid ouput format
$tt->process("$docroot/cart_uuid.tt2", undef, \$output);
ok($output =~ /(.*<p>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}<\/p>.*){2}/is);

foreach (@tests) {
    $tt->process("$docroot/$_", undef, \$output);

    my ($ok, $response, $file) = comp_to_file($output, "$docroot/out/$_.out");

    ok($ok);
};
