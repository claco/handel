#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 9;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class       => 'Handel::Cart::Schema',
    schema_source      => 'Carts',
    item_storage_class => 'Handel::Storage::DBIC::Cart::Item',
    connection_info    => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## get copyable item columns
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity sku/], 'got correct item columns');


## add another primary and make sure it disappears
$storage->schema_instance->source('Items')->set_primary_key(qw/id sku/);
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity/], 'new id column removed from list');


## get them columns when source isn't found
$storage->schema_instance->source('Items')->set_primary_key(qw/id/);
delete $storage->schema_instance->source('Carts')->_relationships->{$storage->item_relationship};
is_deeply([sort $storage->copyable_item_columns], [qw/cart description price quantity sku/], 'column is returned when no in relationship');


## no item storage
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->item_storage_class(undef);
    $storage->item_storage(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/no item storage/i, 'no item in message');
} otherwise {
    fail('other exception caught');
};


## no item relationship
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->item_relationship(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/no item relationship/i, 'no relationship in storage');
} otherwise {
    fail('other exception caught');
};
