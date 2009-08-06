#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $default_values = {
    name        => 'My Default Name',
    description => sub{'My Default Description'}
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

$storage->default_values($default_values);
is_deeply($storage->default_values, $default_values, 'set default values');
