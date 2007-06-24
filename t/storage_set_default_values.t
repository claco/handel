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


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->set_default_values;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('caught other exception');
};


# do nothing if no defaults are set
my $data = {};
$storage->set_default_values($data);
is_deeply($data, {}, 'set default values');


# set the defaults
$data->{'col3'} = 'baz';
$storage->default_values({
    col1 => 'foo', col2 => sub{'bar'}, col3 => 'quix', col4 => []
});
$storage->set_default_values($data);
is_deeply([sort %{$data}], [qw/bar baz col1 col2 col3 foo/], 'set default values');


# do nothing if default_values isn't a hash
$storage->default_values([]);
$data = {};
$storage->set_default_values($data);
is_deeply($data, {}, 'no set if not a hash');
