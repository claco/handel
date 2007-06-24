#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 14;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

## start w/ nothing
is($storage->constraints, undef, 'no constraints defined');


## something from nothing does nothing
is($storage->remove_constraint('foo', 'bar'), undef, 'removing nothing leaves nothing');


my $sub = {};
$storage->constraints({
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    }
});

## remove thing that aren't there
is($storage->remove_constraint('foo', 'name'), undef, 'removed nonexistant constraint');
is($storage->remove_constraint('id', 'name'), undef, 'removed non existant constraint');
is_deeply($storage->constraints, {
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    }
}, 'constraints still defined');


## remove constraint from unconnected schema
$storage->remove_constraint('id', 'Check Id');
is_deeply($storage->constraints, {'id' => {'Check It Again' => $sub}}, 'constraints still defined');


## remove the last one for id, which removes id as well
$storage->remove_constraint('id', 'Check It Again');
is_deeply($storage->constraints, {}, 'removed all constraints');


## throw exception when no column is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraint;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/no column/i, 'no column in message');
} otherwise {
    fail('caught other exception');
};

## throw exception when no name is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraint('col');

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/no constraint name/i, 'no constraint name in message');
} otherwise {
    fail('caught other exception');
};
