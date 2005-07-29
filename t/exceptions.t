#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Handel::Exception', qw(:try));
};


## verify -text and -details propagation
{
    try {
        throw Handel::Exception::Argument(-text => 'foo');
    } catch Handel::Exception with {
        is(shift->text, 'foo')
    };

    try {
        throw Handel::Exception::Argument(-text => 'foo', -details => 'details');
    } catch Handel::Exception with {
        is(shift->text, 'foo: details')
    };
};