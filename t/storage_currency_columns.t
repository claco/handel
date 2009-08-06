#!perl -w
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
is($storage->_currency_columns, undef, 'no currency columns set');
is($storage->currency_columns, 0, 'no currency columns set');


## add columns, and get them back
$storage->_columns([qw/foo bar baz fap/]);
$storage->_currency_columns([qw/foo bar/]);
is_deeply([$storage->currency_columns], [qw/foo bar/], 'set currency columns');


## throw exception when primary column doesn't exists in columns
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        $storage->currency_columns(qw/bar quix/);

        fail('no exception thrown');
    } catch Handel::Exception::Storage with {
        pass('caught storage exception');
        like(shift, qr/does not exist/i, 'column doest exists in message');
    } otherwise {
        fail('caught other exception');
    };
};
