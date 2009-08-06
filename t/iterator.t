#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 37;
    use Scalar::Util qw/refaddr/;

    use_ok('Handel::Iterator');
    use_ok('Handel::Exception', ':try');
};


## test for exception when no hashref is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator->new;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not a hash ref/i, 'message contains not a hash ref');
    } otherwise {
        fail('Other exception caught');
    };
};

## test for exception when no data is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator->new({});

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/data not supplied/i, 'message contains no data');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when no result class is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator->new({
            data => [qw/a b c/]
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/result class not supplied/i, 'result not supplied in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when no storage is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator->new({
            data => [qw/a b c/],
            result_class => 'Foo'
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/storage not supplied/i, 'storage not supplied in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## successful setup
{
    my $data = [qw/a b c/];
    my $storage = bless {}, 'MyStorage';

    my $iterator = Handel::Iterator->new({
        data => $data, result_class => 'MyResult', storage => $storage
    });
    isa_ok($iterator, 'Handel::Iterator');
    is(refaddr $iterator->data, refaddr $data, 'data was set');
    is($iterator->result_class, 'MyResult', 'result class was set');
    is(refaddr $iterator->storage, refaddr $storage, 'storage was set');
};

## test for exception when no result is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = bless {}, 'Handel::Iterator';
        my $result = $iterator->create_result;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/result not supplied/i, 'result not supplied in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when no storage is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = bless {}, 'Handel::Iterator';
        my $result = $iterator->create_result('foo');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/storage not supplied/i, 'storage not supplied in message');
    } otherwise {
        fail('Other exception caught');
    };
};

## test abstract methods
{
    foreach my $method (qw/all count first last next reset/) {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $iterator = bless {}, 'Handel::Iterator';
            $iterator->$method;

            fail('no exception thrown');
        } catch Handel::Exception::Virtual with {
            pass('Argument exception caught');
            like(shift, qr/virtual/i, 'virtual in message');
        } otherwise {
            fail('Other exception caught');
        };
    };
};

SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 7 if $@;
    Test::MockObject->fake_module('MyResult' => (
        create_instance => sub {
            my $class = shift;
            return bless {result => shift, storage => shift}, $class;
        }
    ));
    my $data = [qw/a b c/];
    my $storage = bless {}, 'MyStorage';
    my $iterator = Handel::Iterator->new({
        data => $data, result_class => 'MyResult', storage => $storage
    });
    my $class = ref($iterator); # Needed to avoid segfault! Why?
    isa_ok($class, 'Handel::Iterator');

    ## get result using internal storage
    {
        my $result = $iterator->create_result('foo');
        isa_ok($result, 'MyResult');
        is($result->{'result'}, 'foo', 'result was set');
        is(refaddr $result->{'storage'}, refaddr $storage, 'storage was set');
    };


    ## get result using supplied storage
    {
        my $otherstorage = bless {}, 'MyStorage';
        my $result = $iterator->create_result('foo', $otherstorage);
        isa_ok($result, 'MyResult');
        is($result->{'result'}, 'foo', 'result was set');
        is(refaddr $result->{'storage'}, refaddr $otherstorage, 'storage was set');
    };
};
