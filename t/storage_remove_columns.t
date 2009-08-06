#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 9;

    use_ok('Handel::Storage');
};


## start with nothing
my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');
is($storage->_columns, undef, 'no columns defined');
is($storage->_primary_columns, undef, 'no primary columns defined');


## nothing from nothing does nothing
is($storage->remove_columns, undef, 'no remove columns defined');


## something from nothing is just as worthless
is($storage->remove_columns('foo'), undef, 'no columns removed');

$storage->_columns([qw/foo bar baz/]);
$storage->_primary_columns([qw/foo bar/]);
$storage->_currency_columns([qw/baz bar/]);

## remove a few columns
$storage->remove_columns(qw/foo baz/);
is_deeply($storage->_columns, [qw/bar/], 'removed foo');
is_deeply($storage->_primary_columns, [qw/bar/], 'removed primary foo');
is_deeply($storage->_currency_columns, [qw/bar/], 'removed currency foo');
