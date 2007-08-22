#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 52;
    use Scalar::Util qw/refaddr/;

    use_ok('Handel::Iterator::List');
    use_ok('Handel::Iterator::Results');
    use_ok('Handel::Exception', ':try');
};


## test for exception when no hashref is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::Results->new;

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
        my $iterator = Handel::Iterator::Results->new({});

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/data not supplied/i, 'message contains no data');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when a non blessed data is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::Results->new({
            data => {}
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not an iterator/i, 'not an iterator in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when a blessed, non iterator is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $data = bless {}, 'Handel::Exception';
        my $iterator = Handel::Iterator::Results->new({
            data => $data
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not an iterator/i, 'not an iterator in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when no result class is given
{
    my $storage = bless {}, 'MyStorage';
    my $results = Handel::Iterator::List->new({
        data => [], result_class => 'MyResults', storage => $storage
    });

    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::Results->new({
            data => $results
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/result class not supplied/i, 'no result class in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## and da magic happens here
SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 39 if $@;

    Test::MockObject->fake_module('MyResult' => (
        create_instance => sub {
            my $class = shift;
            return bless {result => shift, storage => shift}, $class;
        }
    ));

    Test::MockObject->fake_module('MyCart' => (
        create_instance => sub {
            my $class = shift;
            return bless {result => shift}, $class;
        }
    ));

    my $storage = bless {}, 'MyStorage';
    my $results = Handel::Iterator::List->new({
        data => [qw/a b c/], result_class => 'MyResult', storage => $storage
    });
    isa_ok($results, 'Handel::Iterator::List');

    my $iterator = Handel::Iterator::Results->new({
        data => $results, result_class => 'MyCart'
    });
    isa_ok($iterator, 'Handel::Iterator::Results');
    is($iterator->count, 3, 'returns count of 3');
    is($results->count, $iterator->count, 'counts match');
    is("$iterator", 3, 'string overloads to count');
    is($iterator + 0, 3, 'num overloads to count');
    if ($iterator) {
        pass('bool overloads to count');
    } else {
        fail('bool overloads to count');
    };


    ## check all
    my @all = $iterator->all;
    is(scalar @all, 3, 'three results in all');
    isa_ok($all[0], 'MyCart');
    is($all[0]->{'result'}->{'result'}, 'a', 'result was stored');
    is(refaddr $all[0]->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');
    isa_ok($all[1], 'MyCart');
    is($all[1]->{'result'}->{'result'}, 'b', 'result was stored');
    is(refaddr $all[1]->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');
    isa_ok($all[2], 'MyCart');
    is($all[2]->{'result'}->{'result'}, 'c', 'result was stored');
    is(refaddr $all[2]->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');


    ## check first
    my $first = $iterator->first;
    isa_ok($first, 'MyCart');
    is($first->{'result'}->{'result'}, 'a', 'result was stored');
    is(refaddr $first->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');


    ## check last
    my $last = $iterator->last;
    isa_ok($last, 'MyCart');
    is($last->{'result'}->{'result'}, 'c', 'result was stored');
    is(refaddr $last->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');


    ## check next
    my $a = $iterator->next;
    isa_ok($a, 'MyCart');
    is($a->{'result'}->{'result'}, 'a', 'result was stored');
    is(refaddr $a->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');

    my $b = $iterator->next;
    isa_ok($b, 'MyCart');
    is($b->{'result'}->{'result'}, 'b', 'result was stored');
    is(refaddr $b->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');

    my $c = $iterator->next;
    isa_ok($c, 'MyCart');
    is($c->{'result'}->{'result'}, 'c', 'result was stored');
    is(refaddr $c->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');

    is($iterator->next, undef, 'iterator returns undef at end');

    $iterator->reset;

    my $d = $iterator->next;
    isa_ok($d, 'MyCart');
    is($d->{'result'}->{'result'}, 'a', 'result was stored');
    is(refaddr $d->{'result'}->{'storage'}, refaddr $storage, 'storage was stored');


    # check methods with empty list
    $iterator->{data}->{data} = [];
    is($iterator->first, undef, 'first returns undef on empty list');
    is($iterator->last, undef, 'last returns undef on empty list');
    is($iterator->next, undef, 'next returns undef on empty list');
};
