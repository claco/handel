#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Catalyst 5.7001';
    plan(skip_all =>
        'Catalyst 5.7001 not installed') if $@;

    eval 'use Catalyst::Devel 1.0';
    plan(skip_all =>
        'Catalyst::Devel 1.0 not installed') if $@;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 13;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    my @models = (
        bless({}, 'Catalyst::Model::Handel::Order'),
        bless({order_class => 'MyOrder'}, 'Catalyst::Model::Handel::Order'),
        bless({order_class => 'BogusOrder'}, 'Catalyst::Model::Handel::Order'),
        bless({order_class => 'Handel::Subclassing::Order', mysetting => 'foo'}, 'Catalyst::Model::Handel::Order'),
    );

    Test::MockObject->fake_module('Catalyst::Model' => (
        new => sub {
            return shift @models;
        }
    ));

    my $orderstorage = Test::MockObject->new;
    $orderstorage->set_always('clone', $orderstorage);
    $orderstorage->mock('mysetting' => sub {
        my $self = shift;

        if (@_) {
            $self->{'mysetting'} = shift;
        };

        return $self->{'mysetting'};
    });
    Test::MockObject->fake_module('Handel::Subclassing::Order' => (
        storage => sub {$orderstorage},
        forwardmethod => sub {return $_[1];},
        new => sub {return $_[1];}
    ));

    my $myorderstorage = Test::MockObject->new;
    $myorderstorage->set_always('clone', $myorderstorage);
    Test::MockObject->fake_module('MyOrder' => (
        storage => sub {$myorderstorage}
    ));

    use_ok('Catalyst::Model::Handel::Order');
    use_ok('Handel::Exception', ':try');
};


## test model with the default class
{
    my $model = Catalyst::Model::Handel::Order->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Order');
    isa_ok($model->order_manager, 'Handel::Order', 'set default order manager');
};


## test model with other class
{
    my $model = Catalyst::Model::Handel::Order->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Order');
    isa_ok($model->order_manager, 'MyOrder', 'set custom order manager');
};


## throw exception when bogus order_class is given
{
    eval {
        local $ENV{'LANGUAGE'} = 'en';
        my $model = Catalyst::Model::Handel::Order->COMPONENT;

        fail('no exception thrown');
    };
    like($@, qr/could not load order class/i, 'could not load class in message');
};


## test model with other unloaded class
{
    my $model = Catalyst::Model::Handel::Order->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Order');
    isa_ok($model->order_manager, 'Handel::Subclassing::Order', 'set custom order manager');
    ok($model->order_manager->storage->called('mysetting'), 'pass mysetting to storage config');
    is($model->order_manager->storage->mysetting, 'foo', 'mysetting was set');
    is($model->forwardmethod('foo'), 'foo', 'methods forwarded to manager instance');
    is($model->new('foonew'), 'foonew', 'new forwarded to manager instance');
};
