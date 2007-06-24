#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 16;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        Test::MockObject->fake_module('Data::FormValidator', check => sub{1});
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## nothing from nothing is nothing
is($storage->validation_profile, undef, 'no validaiton profile set');
is($storage->validate_data({}), undef, 'no validation data is set');




## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->validate_data;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('cauht argument exception');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('caught other exception');
};


## throw exception if not ARRAYREF for FV::S
try {
    local $ENV{'LANG'} = 'en';
    $storage->validation_profile({});
    $storage->validate_data({});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/requires an ARRAYREF/i, 'requires arrayref in message');
} otherwise {
    fail('caught other exception');
};


## just do it
$storage->validation_profile([
    name => ['NOT_BLANK'],
    description => ['NOT_BLANK', ['LENGTH', 2, 4]]
]);

my $results = $storage->validate_data({
    name => 'foo', description => 'bar'
});
isa_ok($results, 'FormValidator::Simple::Results');
ok($results->success, 'validation succeeded');



## bad data!
$results = $storage->validate_data({
    name => '', description => 'stuffs'
});
isa_ok($results, 'FormValidator::Simple::Results');
ok(!$results->success, 'validaiton failed');


SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 3 if $@;


    ## throw exception if not HASHREF for D::FV
    try {
        local $ENV{'LANG'} = 'en';
        $storage->validation_module('Data::FormValidator');
        $storage->validation_profile([]);
        $storage->validate_data({});

        fail('no exception thrown');
    } catch Handel::Exception::Storage with {
        pass('caught storage exception');
        like(shift, qr/requires an HASHREF/i, 'requires hashref in message');
    } otherwise {
        fail('caught other exception');
    };


    $storage->validation_profile({});
    ok($storage->validate_data({}), 'unset validation profile');
};
