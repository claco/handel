#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 12;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};

my $storage = Test::MockObject->new;
$storage->set_series('autoupdate', 1, 0, 1, 0);
$storage->set_false('_item_storage');

my $result = Test::MockObject->new;
$result->set_always('storage', $storage);


## create instance with autoupdates from class
{
    my $instance = Handel::Base->create_instance($result);
    isa_ok($instance, 'Handel::Base');
    is($instance->autoupdate, 1, 'instance autoupdates are on');
    is(refaddr $instance->result, refaddr $result, 'results match');
    is(refaddr $instance->storage, refaddr $storage, 'storage matches');
};


## create instance without autoupdates from class
{
    my $instance = Handel::Base->create_instance($result);
    isa_ok($instance, 'Handel::Base');
    is($instance->autoupdate, 0, 'instance autoupdates are off');
    is(refaddr $instance->result, refaddr $result, 'results match');
    is(refaddr $instance->storage, refaddr $storage, 'storage matches');
};


## throw exception when result is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $instance = Handel::Base->create_instance;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('caught argument exception');
        like(shift, qr/no result/i, 'no result in message');
    } otherwise {
        fail('other exception caught');
    };
};


## throw exception when called as object method
#{
#    try {
#        local $ENV{'LANGUAGE'} = 'en';
#        my $base = bless {}, 'Handel::Base';
#        my $instance = $base->create_instance($result);
#
#        fail('no exception thrown');
#    } catch Handel::Exception with {
#        pass;
#        like(shift, qr/object method/i);
#    } otherwise {
#        fail;
#    };
#};
