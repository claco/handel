#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Handel::TestHelper qw/comp_to_file/;
    use Config;

    plan(skip_all => 'Skipping tests under uselongdouble') if $Config{'uselongdouble'};

    eval 'use Template 2.07';
    plan(skip_all => 'Template Toolkit 2.07 not installed') if $@;

    eval 'use DBD::SQLite';
    plan(skip_all => 'DBD::SQLite not installed') if $@;
};

## test new/add first so we can use them to test everything else
## convert these to TT2
my @tests = (
    'order_create.tt2',
    'order_create_cart.tt2',
    'order_create_and_add.tt2',
    'order_fetch.tt2',
    'order_fetch_as_array.tt2',
    'order_fetch_as_iterator.tt2',
    'order_fetch_filtered.tt2',
    'order_fetch_filtered_no_results.tt2',
    'order_add.tt2',
    'order_clear.tt2',
    'order_delete.tt2',
    'order_update.tt2',
    'order_items.tt2',
    'order_items_as_array.tt2',
    'order_items_as_iterator.tt2',
    'order_items_filtered.tt2',
    'order_items_filtered_no_results.tt2',
    'order_items_update.tt2'
);

## Setup SQLite DB for tests
my $schema = Handel::Test->init_schema(no_order => 1);
local $ENV{'HandelDBIDSN'} = $schema->dsn;

plan(tests => (scalar @tests) + 1);

my $tt      = Template->new() || die 'Error creating Template';
my $docroot = 't/htdocs/tt2';
my $output  = '';

## test uuid ouput format
$tt->process("$docroot/order_uuid.tt2", undef, \$output);
ok($output =~ /(.*<p>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}<\/p>.*){1}/is, 'uuid test generated uuids');

foreach my $test (@tests) {
    my $output = '';
    $tt->process("$docroot/$test", undef, \$output);

    my ($ok, $response, $file) = comp_to_file($output, "$docroot/out/$test.out");

    if (!$ok) {
        diag("Test: $test");
        diag("Error:\n" . $tt->error) if $tt->error;
        diag("Expected:\n", $file);
        diag("Received:\n", $response);
    };

    ok($ok, "$test was successful");
};
