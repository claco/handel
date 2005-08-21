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
    'checkout_plugins.tt2',
    'checkout_phases.tt2',
    'checkout_messages.tt2',
    'checkout_process.tt2',
    'checkout_order.tt2'
);

## Setup SQLite DB for tests
{
    my $dbfile  = "t/htdocs/tt2.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";

    unlink $dbfile;
    preparetables($db, [qw(cart order)], 1);

    local $^W = 0;
    Handel::DBI->connection($db);
};

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

    ok($ok);
};
