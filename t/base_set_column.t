#!/usr/bin/perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 20;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


## fake result object
my $result = Test::MockObject->new;
$result->set_true('col1');
$result->set_true('col2');
$result->set_always('update');


## set the result and basic accessor map
my $base = bless {}, 'Handel::Base';
$base->result($result);
$base->accessor_map({
    foo => 'col1'
});


## set column via accessor map with autoupdates
$base->autoupdate(1);
ok(!$result->called('update'), 'update not called yet');
$base->set_column('foo');
ok($result->called('col1'), 'set_column using accessor mapping');
ok($result->called('update'), 'set_column triggers update');
$result->clear;


## set column with no map match with autoupdates
$base->autoupdate(1);
ok(!$result->called('update'), 'update not called yet');
$base->set_column('col2');
ok($result->called('col2'), 'set_column missing accessor mapping');
ok($result->called('update'), 'set_column triggers update');
$result->clear;


## set column via accessor map without autoupdates
$base->autoupdate(0);
ok(!$result->called('update'), 'update not called yet');
$base->set_column('foo');
ok($result->called('col1'), 'set_column using accessor mapping');
ok(!$result->called('update'), 'no update without autoupdate');
$result->clear;


## set column with no map match without autoupdates
$base->autoupdate(0);
ok(!$result->called('update'), 'update not called yet');
$base->set_column('col2');
ok($result->called('col2'), 'set_column missing accessor mapping');
ok(!$result->called('update'), 'no update without autoupdate');
$result->clear;

## throw exception when no column param is sent
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        $base->set_column;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when column param is empty
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        $base->set_column('');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception as a class method
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        Handel::Base->set_column;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/not a class method/i, 'not a class method in message');
    } otherwise {
        fail('Other exception thrown');
    };
};
