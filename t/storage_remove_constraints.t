#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 10;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->constraints, undef, 'no constraints set');


## something from nothing does nothing
is($storage->remove_constraints('foo'), undef, 'no constraints set');


my $sub = {};
$storage->constraints({
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    },
    name => {
        'Check Name' => $sub,
        'Check Name Again' => $sub
    }
});


## remove constraints from column
$storage->remove_constraints('name');
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub, 'Check It Again' => $sub}}, 'removed constraint');


## do id again
is($storage->remove_constraints('name'), undef, 'remove non existant does nothing');
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub, 'Check It Again' => $sub}}, 'constraints unchanged');


## throw exception when no column is specified
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->remove_constraints;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/no column/i, 'no column in message');
} otherwise {
    fail('caught other exception');
};
