#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(preparetables comp_to_file);
use Handel::DBI;

eval 'use Template 2.07';
    plan(skip_all => 'Template Toolkit 2.07 not installed') if $@;

eval 'use DBD::SQLite';
    plan(skip_all => 'DBD::SQLite not installed') if $@;


## test new/add first so we can use them to test everything else
## convert these to TT2
my @tests = (
    'cart_create.tt2',
    'cart_create_and_add.tt2',
    'cart_fetch.tt2',
    'cart_fetch_as_array.tt2',
    'cart_fetch_as_iterator.tt2',
    'cart_fetch_filtered.tt2',
    'cart_fetch_filtered_no_results.tt2',
    'cart_add.tt2',
    'cart_clear.tt2',
    'cart_delete.tt2',
    'cart_update.tt2',
    'cart_save.tt2',
    'cart_items.tt2',
    'cart_items_as_array.tt2',
    'cart_items_as_iterator.tt2',
    'cart_items_filtered.tt2',
    'cart_items_filtered_no_results.tt2',
    'cart_items_update.tt2',
    'cart_restore_append.tt2',
    'cart_restore_replace.tt2',
    'cart_restore_merge.tt2',
);

## Setup SQLite DB for tests
{
    my $dbfile  = "t/htdocs/tt2.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";

    unlink $dbfile;
    preparetables($db, ['cart']);

    local $^W = 0;
    Handel::DBI->connection($db);
};

plan(tests => (scalar @tests) + 1);

my $tt      = Template->new() || die 'Error creating Template';
my $docroot = 't/htdocs/tt2';
my $output  = '';

## test uuid ouput format
$tt->process("$docroot/cart_uuid.tt2", undef, \$output);
ok($output =~ /(.*<p>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}<\/p>.*){2}/is);

foreach (@tests) {
    my $output = '';
    $tt->process("$docroot/$_", undef, \$output);

    my ($ok, $response, $file) = comp_to_file($output, "$docroot/out/$_.out");

    if (!$ok) {
        diag("Test: $_");
        diag("Error:\n" . $tt->error) if $tt->error;
        diag("Expected:\n", $file);
        diag("Received:\n", $response);
    };

    ok($ok);
};
