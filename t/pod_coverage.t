#!perl -wT
# $Id: pod_coverage.t 4 2004-12-28 03:01:15Z claco $
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 not installed' if $@;

all_pod_coverage_ok();
