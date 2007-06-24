#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 5;

    use_ok('Handel::Storage');
};


## start with nothing
my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');
is($storage->_columns, undef, 'no columns defined');


## add a few columns
$storage->add_columns(qw/foo bar/);
$storage->add_columns(qw/baz/);
is_deeply($storage->_columns, [qw/foo bar baz/], 'added columns');

$storage->add_columns;
is_deeply($storage->_columns, [qw/foo bar baz/], 'added no columns');
