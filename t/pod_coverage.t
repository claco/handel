#!perl -wT
# $Id$
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 not installed' if $@;

my $trustme = { trustme => [qr/^new$/] };

all_pod_coverage_ok($trustme);
