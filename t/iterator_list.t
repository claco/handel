#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 36;
    use Scalar::Util qw/refaddr/;

    use_ok('Handel::Iterator::List');
    use_ok('Handel::Exception', ':try');
};


## test for exception when non-ARRAY is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::List->new({
            data => {}
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not an array ref/i, 'not array ref in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## make sure exceptions pass through
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::List->new({
            data => []
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/result class not supplied/i, 'result class not supplied in message');
    } otherwise {
        fail('Other exception caught');
    };
};


SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 30 if $@;

    Test::MockObject->fake_module('MyResult' => (
        create_instance => sub {
            my $class = shift;
            return bless {result => shift, storage => shift}, $class;
        }
    ));

    my $storage = bless {}, 'MyStorage';
    my $iterator = Handel::Iterator::List->new({
        data => [qw/a b c/], result_class => 'MyResult', storage => $storage
    });
    isa_ok($iterator, 'Handel::Iterator::List');
    is($iterator->count, 3, 'count returns 3');
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
    is($all[0]->{'result'}, 'a', 'result 1 result is set');
    is(refaddr $all[0]->{'storage'}, refaddr $storage, 'result 1 storage is set');
    is($all[1]->{'result'}, 'b', 'result 2 result is set');
    is(refaddr $all[1]->{'storage'}, refaddr $storage, 'result 2 storage is set');
    is($all[2]->{'result'}, 'c', 'result 3 result is set');
    is(refaddr $all[2]->{'storage'}, refaddr $storage, 'result 3 storage is set');


    ## check first
    my $first = $iterator->first;
    isa_ok($first, 'MyResult');
    is($first->{'result'}, 'a', 'firsts result is set');
    is(refaddr $first->{'storage'}, refaddr $storage, 'firsts storage is set');


    ## check last
    my $last = $iterator->last;
    isa_ok($last, 'MyResult');
    is($last->{'result'}, 'c', 'lasts result is set');
    is(refaddr $last->{'storage'}, refaddr $storage, 'lasts storage is set');
    

    ## check next
    my $a = $iterator->next;
    is($a->{'result'}, 'a', 'a result is set');
    is(refaddr $a->{'storage'}, refaddr $storage, 'a storage is set');

    my $b = $iterator->next;
    is($b->{'result'}, 'b', 'b result is set');
    is(refaddr $b->{'storage'}, refaddr $storage, 'b storage is set');

    my $c = $iterator->next;
    is($c->{'result'}, 'c', 'c result is set');
    is(refaddr $c->{'storage'}, refaddr $storage, 'c storage is set');

    is($iterator->next, undef, 'end of list returns nothing on next');


    # check reset
    $iterator->reset;
    my $a2 = $iterator->next;
    is($a2->{'result'}, 'a', 'a2 result is set');
    is(refaddr $a2->{'storage'}, refaddr $storage, 'a2 storage is set');


    # check methods with empty list
    $iterator->{data} = [];
    is($iterator->first, undef, 'first returns undef on empty list');
    is($iterator->last, undef, 'last returns undef on empty list');
    is($iterator->next, undef, 'next returns undef on empty list');
};
