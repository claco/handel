#!/usr/bin/perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 10;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


## fake result object
my $result = Test::MockObject->new;
$result->set_always('col1', 'Column1');
$result->set_always('col2', 'Column2');


## set the result and basic accessor map
my $base = bless {}, 'Handel::Base';
$base->result($result);
$base->accessor_map({
    foo => 'col1'
});


## the magic happens here
is($base->get_column('foo'), 'Column1', 'get_column using accessor mapping');
is($base->get_column('col2'), 'Column2', 'get_column real name');


## throw exception when no column param is sent
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        $base->get_column;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in exception message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when column param is empty
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        $base->get_column('');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in exception message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception as a class method
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        Handel::Base->get_column;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/not a class method/i, 'not a class method in message');
    } otherwise {
        fail('Other exception thrown');
    };
};
