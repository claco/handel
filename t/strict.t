#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use File::Find;
use File::Basename;

eval 'use Test::Strict';
plan skip_all => 'Test::Strict not installed' if $@;

plan skip_all => 'Need untaint in newer File::Find' if $] <= 5.006;

## I hope this can go away if Test::Strict or File::Find::Rule
## finally run under -T. Until then, I'm on my own here. ;-)
my @files;
my %trusted = (
    'apache_test_config.pm' => 1,
    'modperl_inc.pl'        => 1,
    'modperl_startup.pl'    => 1
);

find({  wanted => \&wanted,
        untaint => 1,
        untaint_pattern => qr|^([-+@\w./]+)$|,
        untaint_skip => 1,
        no_chdir => 1
}, qw(lib t));

sub wanted {
    my $name = $File::Find::name;
    my $file = fileparse($name);

    return if $name =~ /TestApp/;

    if ($name =~ /\.(pm|pl|t)$/i && !exists($trusted{$file})) {
        push @files, $name;
    };
};

if (scalar @files) {
    plan tests => scalar @files;
} else {
    plan tests => 1;
    fail 'No perl files found for Test::Strict checks!';
};

foreach (@files) {
    strict_ok($_);
};
