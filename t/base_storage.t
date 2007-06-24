#!perl -wT
# $Id$
use strict;
use warnings;

my $initialstorage;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 29;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    $initialstorage = bless {}, 'Handel::Storage';
    Test::MockObject->fake_module('Handel::Storage' => (
        new => sub {$initialstorage},
        _item_storage => sub {}
    ));

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


## get storage on class
{
    my $storage = Handel::Base->storage;
    isa_ok($storage, 'Handel::Storage', 'storage returns Handel::Storage');
    is(refaddr $storage, refaddr $initialstorage, 'class storage call returns class storage');
};


## get storage on object with no object storage
{
    my $base = bless {}, 'Handel::Base';
    my $storage = $base->storage;
    isa_ok($storage, 'Handel::Storage', 'storage returns Handel::Storage');
    is(refaddr $storage, refaddr $initialstorage, 'object storage call returns class storage');
};


## get storage on object with with object storage first
{
    my $storage = bless {}, 'Handel::Storage';
    my $base = bless {storage => $storage}, 'Handel::Base';
    my $newstorage = $base->storage;
    isa_ok($newstorage, 'Handel::Storage', 'storage returns Handel::Storage');
    is(refaddr $newstorage, refaddr $storage, 'object storage call returns object storage');
    isnt(refaddr $newstorage, refaddr $initialstorage, 'object storage no class storage');
};


## set item storage if item class is set and no _item_storage exists
{
    my $storage = Test::MockObject->new;
    $storage->set_false('_item_storage');
    $storage->mock('item_storage', sub {
        my ($self, $s) = @_;
        $self->{'is'} = $s if $s;

        return $self->{'is'};
    });

    my $itemstorage = Test::MockObject->new;
    Test::MockObject->fake_module('FakeItemClass' => (
        storage => sub {$itemstorage}
    ));

    my $base = bless{item_class => 'FakeItemClass', storage => $storage}, 'Handel::Base';
    my $newstorage = $base->storage;
    is(refaddr $newstorage, refaddr $storage, 'storage returned object storage');
    is(refaddr $itemstorage, refaddr $newstorage->item_storage, 'item storage set if item_class is set');
    ok($storage->called('item_storage'), 'item_storage was called');
};


## don't item storage if item class is set but _item_storage exists
{
    my $storage = Test::MockObject->new;
    $storage->set_true('_item_storage');
    $storage->set_always('item_storage' => 'foo');

    Test::MockObject->fake_new('FakeItemClass');

    my $base = bless{item_class => 'FakeItemClass', storage => $storage}, 'Handel::Base';
    my $newstorage = $base->storage;
    is(refaddr $newstorage, refaddr $storage, 'storage returned object storage');
    ok(!$storage->called('item_storage'), 'never called item_Storage');
    is($newstorage->item_storage, 'foo', 'item storage left alone');
};


## pass args to setup if specified
{
    my $storage = Test::MockObject->new;
    $storage->set_true('_item_storage');
    $storage->mock('setup' => sub {
        my ($self, $args) = @_;
        $self->{'args'} = $args if $args;

        return $self->{'args'};
    });
    my $base = bless{storage => $storage}, 'Handel::Base';
    my $newstorage = $base->storage({'foo' => 'bar'});
    ok($storage->called('setup'), 'setup called with args');
    is_deeply($newstorage->{'args'}, {'foo' => 'bar'}, 'setup called with args');
};


## don't assign storage if it's not a Handel::Storage subclass
{
    my $storage = Test::MockObject->new;
    $storage->set_true('_item_storage');

    my $newstorage = Test::MockObject->new;
    my $base = bless {storage => $storage}, 'Handel::Base';

    $base->storage($storage);
    is(refaddr $base->storage, refaddr $storage, 'non isa storage not set');
};


## assign storage to class if it's a Handel::Storage subclass
{
    my $storage = Test::MockObject->new;
    $storage->set_true('_item_storage');

    my $newstorage = Test::MockObject->new;
    $newstorage->set_true('_item_storage');
    $newstorage->set_isa('Handel::Storage');

    Handel::Base->storage($newstorage);
    is(refaddr $Handel::Base::_storage, refaddr $newstorage, 'isa storage set');
};


## assign storage to object if it's a Handel::Storage subclass
{
    my $storage = Test::MockObject->new;
    $storage->set_true('_item_storage');

    my $newstorage = Test::MockObject->new;
    $newstorage->set_true('_item_storage');
    $newstorage->set_isa('Handel::Storage');

    my $base = bless {storage => $storage}, 'Handel::Base';
    $base->storage($newstorage);
    is(refaddr $base->storage, refaddr $newstorage, 'isa storage set');
};


## has_storage returns undef if nothing is set on class
{
    local $Handel::Base::_storage = undef;
    is(Handel::Base->has_storage, undef, 'has no storage');
};


## has_storage returns undef if nothing is set on object
{
    local $Handel::Base::_storage = undef;
    my $base = bless {}, 'Handel::Base';
    is($base->has_storage, undef, 'has no storage');
};


## has_storage returns 1 if set on class
{
    local $Handel::Base::_storage = 1;
    is(Handel::Base->has_storage, 1, 'has class storage');
};


## has_storage returns 1 if set on class
{
    local $Handel::Base::_storage = 1;
    my $base = bless {}, 'Handel::Base';
    is($base->has_storage, 1, 'has class storage');
};


## has_storage returns 1 if set on object
{
    local $Handel::Base::_storage = undef;
    my $base = bless {storage => 1}, 'Handel::Base';
    is($base->has_storage, 1, 'has class storage');
};


# get supers storage
{
    Test::MockObject->fake_new('MyStorage');
    @MyStorage::ISA = 'Handel::Base';
    $MyStorage::_storage = undef;

    my $clonestorage = bless {}, 'Handel::Storage';

    Test::MockObject->fake_module('Handel::Storage' => (
        clone => sub {$clonestorage}
    ));
    my $storage = bless {}, 'Handel::Storage';
    local $Handel::Base::_storage = $storage;

    my $newstorage = MyStorage->storage;
    is(refaddr $newstorage, refaddr $clonestorage, 'received clone storage from super');
};


# don't get supers storage if it's not the same as our storage class
{
    Test::MockObject->fake_new('MyStorage');
    @MyStorage::ISA = 'Handel::Base';
    $MyStorage::_storage = undef;

    my $createstorage = bless {}, 'Handel::Storage';
    Test::MockObject->fake_module('Handel::Storage' => (
        new => sub {$createstorage}
    ));
    my $storage = bless {}, 'Not::Handel::Storage';
    local $Handel::Base::_storage = $storage;

    my $newstorage = MyStorage->storage;
    is(refaddr $newstorage, refaddr $createstorage, 'received new storage from self');
};


# get supers storage and unset cloned item storage
{
    Test::MockObject->fake_new('MyStorage');
    @MyStorage::ISA = 'Handel::Base';
    $MyStorage::_storage = undef;

    my $clonestorage = bless {_item_storage => 1}, 'Handel::Storage';

    Test::MockObject->fake_module('Handel::Storage' => (
        clone => sub {$clonestorage},
        _item_storage => sub {
            my $self = shift;

            if (@_) {
                $self->{'_item_storage'} = shift;
            };
            return $self->{'_item_storage'};
        }
    ));
    my $storage = bless {}, 'Handel::Storage';
    local $Handel::Base::_storage = $storage;

    my $newstorage = MyStorage->storage;
    is(refaddr $newstorage, refaddr $clonestorage, 'received clone storage from super');
    is($newstorage->_item_storage, undef, 'item storage was unset');
};
