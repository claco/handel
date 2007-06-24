#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Handel::TestHelper qw/comp_to_file/;

    eval 'use Template 2.07';
    plan(skip_all => 'Template Toolkit 2.07 not installed') if $@;
};


## test new/add first so we can use them to test everything else
## convert these to TT2
my @tests = (
    'constants.tt2'
);

plan(tests => (scalar @tests));

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
