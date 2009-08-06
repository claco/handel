#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 5;

    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->_columns, undef, 'no columns set');
is($storage->columns, 0, 'no columns set');


## add columns, and get them back
$storage->_columns([qw/foo bar baz/]);
is_deeply([$storage->columns], [qw/foo bar baz/], 'return current columns');
