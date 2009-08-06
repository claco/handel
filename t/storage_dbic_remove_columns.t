#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 13;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});

my $item_storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Items',
    remove_columns   => ['quantity']
});
$storage->item_storage($item_storage);


## We have nothing
is($storage->_columns_to_remove, undef, 'no columns defined');


## Remove without schema instance adds to collection
$storage->remove_columns(qw/foo/);
is($storage->_schema_instance, undef, 'no schema instance');
is_deeply($storage->_columns_to_remove, [qw/foo/], 'stored columns to remove');
$storage->remove_columns(qw/bar/);
is_deeply($storage->_columns_to_remove, [qw/foo bar/], 'appended columns to remove');
$storage->_columns_to_remove(undef);


## Remove from a connected schema
my $schema = $storage->schema_instance;
ok($schema->source($storage->schema_source)->has_column('name'), 'have name column');
ok($schema->class($storage->schema_source)->can('name'), 'has name column accessor');
$storage->remove_columns('name');
is_deeply($storage->_columns_to_remove, [qw/name/], 'added name to remove columns');
$schema->source('Carts')->remove_columns('name');
ok(!$schema->source($storage->schema_source)->has_column('name'), 'name column is gone from has_columns');
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
ok(!$schema->source($item_storage->schema_source)->has_column('quantity'), 'quantity column removed from item storage');


## dbic doesn't remove the accessor method, but it should throw and exception
try {
    local $ENV{'LANGUAGE'} = 'en';
    $cart->name;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no such column/i, 'dbic exception on accessor without column');
} otherwise {
    fail('other exception caught');
};
