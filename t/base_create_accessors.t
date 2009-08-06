#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 16;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


## fake storage object
my $storage = Test::MockObject->new;
$storage->set_series('column_accessors' =>
    {col1 => 'foo', col2 => 'col2'}, undef, {}
);
$storage->set_false('_item_storage');
$Handel::Base::_storage = $storage;


## create accessors
{
    is(Handel::Base->accessor_map, undef, 'no accessor map defined');
    ok(!Handel::Base->can('foo'), 'can not yet do foo');
    ok(!Handel::Base->can('col1'), 'can not yet do col1');
    ok(!Handel::Base->can('col2'), 'can not yet do col2');

    Handel::Base->create_accessors;

    can_ok('Handel::Base', 'foo');
    can_ok('Handel::Base', 'col2');
    ok(!Handel::Base->can('col1'), 'still no col1 method');
    is_deeply(Handel::Base->accessor_map, {col1 => 'foo', col2 => 'col2'}, 'accessor map set after create');
};


## throw exception when storage returns no column accessors
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        Handel::Base->create_accessors;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/column accessors/i, 'no column accessors in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when storage returns no column accessors
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        Handel::Base->create_accessors;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/column accessors/i, 'no column accessors in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception as an object method
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $base = bless {}, 'Handel::Base';
        $base->create_accessors;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/not an object method/i, 'not an object method in message');
    } otherwise {
        fail('Other exception thrown');
    };
};
