#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

    eval 'use Test::Pod::Coverage 1.04';
    plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

    eval 'use Pod::Coverage 0.14';
    plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;
};

my $trustme = {
    trustme =>
    [qr/^(COMPONENT|throw_exception|(get|set)_component_(class|data)|quoted_text|constant_text|insert|update|accessor_name|stringify|newuuid|FETCH|STORE|DELETE|EXISTS|CLEAR|new|load|handler|register|(pop|push)_context|parse_(char|end|start)|start_document|.*_(char|start|end))$/]
};

{
    ## trap Handel::Compat deprecated warnings
    $SIG{__WARN__} = sub{};
    require Handel::Compat;
};

all_pod_coverage_ok($trustme);
