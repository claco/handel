#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $validation = [
    name => ['NOT_BLANK'],
    description => ['NOT_BLANK', ['LENGTH', 2, 4]]
];

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


$storage->validation_profile($validation);
is_deeply($storage->validation_profile, $validation, 'set validation profile');
