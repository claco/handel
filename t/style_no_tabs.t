#!perl -wT
# $Id$
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;

plan skip_all => 'set TEST_NOTABS or TEST_PRIVATE to enable this test' unless $ENV{TEST_NOTABS} || $ENV{TEST_PRIVATE};

eval 'use Test::NoTabs 0.03';
plan skip_all => 'Test::NoTabs 0.03 not installed' if $@;

all_perl_files_ok('lib');
