#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 8;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->_primary_columns, undef, 'no primary columns defined');
is($storage->primary_columns, 0, 'no primary columns defined');


## add columns, and get them back
$storage->_columns([qw/foo bar baz fap/]);
$storage->_primary_columns([qw/foo bar baz/]);
is_deeply([$storage->primary_columns], [qw/foo bar baz/], 'added primary columns');


## throw exception when primary column doesn't exists in columns
{
    try {
        $storage->primary_columns(qw/bar quix/);

        fail('no exception thrown');
    } catch Handel::Exception::Storage with {
        pass('caught storage exception');
        like(shift, qr/does not exist/i, 'column does not exist in messages');
    } otherwise {
        fail('caught other exception');
    };
};
