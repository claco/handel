#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 47;
    };

    use_ok('Handel::Iterator::DBIC');
    use_ok('Handel::Exception', ':try');
};


## test for exception when non-DBIC is given
{
    my $data = bless {}, 'Handel::Iterator';
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::DBIC->new({
            data => $data
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not a DBIx::Class::Resultset/i, 'not a resultset in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## test for exception when non-blessed is given
{
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::DBIC->new({
            data => {}
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/not a DBIx::Class::Resultset/i, 'not a resultset in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## make sure exceptions pass through
{
    my $data = bless {}, 'DBIx::Class::ResultSet';
    try {
        local $ENV{'LANGUAGE'} = 'en';
        my $iterator = Handel::Iterator::DBIC->new({
            data => $data
        });

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception caught');
        like(shift, qr/result class not supplied/i, 'no result in message');
    } otherwise {
        fail('Other exception caught');
    };
};


## make it happen cappen
SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 39 if $@;

    Test::MockObject->fake_module('MyResult' => (
        create_instance => sub {
            my $class = shift;
            return bless {result => shift, storage => shift}, $class;
        }
    ));

    my $storage = bless {}, 'MyStorage';
    my $schema = Handel::Test->init_schema(no_orders => 1);
    my $resultset = $schema->resultset('Carts')->search;
    is($resultset->count, 3, 'three carts in resultset');

    my $iterator = Handel::Iterator::DBIC->new({
        data => $resultset, result_class => 'MyResult', storage => $storage
    });
    isa_ok($iterator, 'Handel::Iterator::DBIC');
    is($iterator->count, 3, 'returns count of 3');
    is($resultset->count, $iterator->count, 'counts match');
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
    isa_ok($all[0], 'MyResult');
    is($all[0]->{'result'}->id, '11111111-1111-1111-1111-111111111111', 'result was stored');
    is(refaddr $all[0]->{'storage'}, refaddr $storage, 'storage was stored');
    isa_ok($all[1], 'MyResult');
    is($all[1]->{'result'}->id, '22222222-2222-2222-2222-222222222222', 'result was stored');
    is(refaddr $all[1]->{'storage'}, refaddr $storage, 'storage was stored');
    isa_ok($all[2], 'MyResult');
    is($all[2]->{'result'}->id, '33333333-3333-3333-3333-333333333333', 'result was stored');
    is(refaddr $all[2]->{'storage'}, refaddr $storage, 'storage was stored');


    ## check first
    my $first = $iterator->first;
    isa_ok($first, 'MyResult');
    is($first->{'result'}->id, '11111111-1111-1111-1111-111111111111', 'result was stored');
    is(refaddr $first->{'storage'}, refaddr $storage, 'storage was stored');


    ## check last
    my $last = $iterator->last;
    isa_ok($last, 'MyResult');
    is($last->{'result'}->id, '33333333-3333-3333-3333-333333333333', 'result was stored');
    is(refaddr $last->{'storage'}, refaddr $storage, 'storage was stored');


    ## check next
    my $a = $iterator->next;
    isa_ok($a, 'MyResult');
    is($a->{'result'}->id, '11111111-1111-1111-1111-111111111111', 'result was stored');
    is(refaddr $a->{'storage'}, refaddr $storage, 'storage was stored');

    my $b = $iterator->next;
    isa_ok($b, 'MyResult');
    is($b->{'result'}->id, '22222222-2222-2222-2222-222222222222', 'result was stored');
    is(refaddr $b->{'storage'}, refaddr $storage, 'storage was stored');

    my $c = $iterator->next;
    isa_ok($c, 'MyResult');
    is($c->{'result'}->id, '33333333-3333-3333-3333-333333333333', 'result was stored');
    is(refaddr $c->{'storage'}, refaddr $storage, 'storage was stored');

    is($iterator->next, undef, 'return undef when data is done');
    
    $iterator->reset;

    my $d = $iterator->next;
    isa_ok($d, 'MyResult');
    is($d->{'result'}->id, '11111111-1111-1111-1111-111111111111', 'result was stored');
    is(refaddr $d->{'storage'}, refaddr $storage, 'storage was stored');


    # check methods with empty list
    $iterator->{data} = $schema->resultset('Carts')->search({id => '0'});
    is($iterator->first, undef, 'first returns undef on empty list');
    is($iterator->last, undef, 'last returns undef on empty list');
    is($iterator->next, undef, 'next returns undef on empty list');
};
