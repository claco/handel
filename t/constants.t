#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN {
    use_ok('Handel::Constants', qw(:all));
};

foreach my $const (@Handel::Constants::EXPORT_OK) {
    can_ok(__PACKAGE__, $const);
    if ($const =~ /[A-Z_]/g) {
        is(str_to_const($const), Handel::Constants->$const);
    };
};
