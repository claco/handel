#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Handel::TestHelper qw/comp_to_file/;

    eval 'use Template 2.07';
    plan(skip_all => 'Template Toolkit 2.07 not installed') if $@;

    eval 'use DBD::SQLite';
    plan(skip_all => 'DBD::SQLite not installed') if $@;
};

## test new/add first so we can use them to test everything else
## convert these to TT2
my @tests = (
    'checkout_plugins.tt2',
    'checkout_phases.tt2',
    'checkout_messages.tt2',
    'checkout_process.tt2',
    'checkout_order.tt2'
);

## Setup SQLite DB for tests
my $schema = Handel::Test->init_schema;
local $ENV{'HandelDBIDSN'} = $schema->dsn;

plan(tests => scalar @tests);

my $tt      = Template->new() || die 'Error creating Template';
my $docroot = 't/htdocs/tt2';
my $output  = '';

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
