#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme =>
    [qr/^(accessor_name|stringify|newuuid|FETCH|STORE|DELETE|EXISTS|CLEAR|new|load|(pop|push)_context|parse_(char|end|start)|start_document)$/]
};

all_pod_coverage_ok($trustme);
