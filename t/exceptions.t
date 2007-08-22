#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 44;
    use_ok('Handel::Exception', qw(:try));
};


## verify -text and -details propagation
{
    try {
        throw Handel::Exception::Argument(-text => 'foo');

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        is(shift->text, 'foo', 'got foo message')
    } otherwise {
        fail('Other exception thrown');
    };

    try {
        throw Handel::Exception::Argument(-text => 'foo', -details => 'details');

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        is($_[0]->text, 'foo: details', 'got foo message with details');
        is($_[0]->details, 'details', 'details set');
    } otherwise {
        fail('Other exception thrown');
    };
};


## get default text
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        throw Handel::Exception;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        like($_[0]->text, qr/unspecified/, 'unhandled exception in message');
        is($_[0]->details, undef, 'details not set');
    } otherwise {
        fail('Other exception thrown');
    };
};


## don't set details if it's a ref
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        throw Handel::Exception(-details => {foo => 'bar'});

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        is($_[0]->text, 'An unspecified error has occurred', 'unhandled exception in message');
        is_deeply($_[0]->details, {foo => 'bar'}, 'details still set');
    } otherwise {
        fail('Other exception thrown');
    };
};


## set the results
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        throw Handel::Exception( -results => {foo => 'bar'});

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        like($_[0]->text, qr/unspecified/, 'unhandled exception in message');
        is($_[0]->details, undef, 'details not set');
        is_deeply($_[0]->results, {foo => 'bar'}, 'results were set');
    } otherwise {
        fail('Other exception thrown');
    };
};


## make sure everyone still works
foreach (qw/Taglib Order Checkout Constraint Storage Validation Virtual/) {
    my $class = "Handel::Exception::$_";
    try {
        local $ENV{'LANGUAGE'} = 'en';
        throw $class;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        isa_ok($_[0], 'Handel::Exception');
        ok($_[0]->text, 'test is set');
        is($_[0]->details, undef, 'details not set');
    } otherwise {
        fail('Other exception thrown');
    };
};
