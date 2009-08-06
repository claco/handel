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
        plan tests => 48;
    };

    use_ok('Handel::Storage::DBIC');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## return column accessors for unconnect schema as-is
$storage->schema_class->source('Carts')->column_info('id')->{'accessor'} = 'id';
my $accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 5, 'got 5 columns');
ok(exists $accessors->{'id'}, 'got id accessor');
ok(exists $accessors->{'shopper'}, 'got sohpper accessor');
ok(exists $accessors->{'type'}, 'got type accessor');
ok(exists $accessors->{'name'}, 'got name accessor');
ok(exists $accessors->{'description'}, 'got description accessor');
is($accessors->{'id'}, 'id', 'id accessor is id');
is($accessors->{'shopper'}, 'shopper', 'shopper accessor is shopper');
is($accessors->{'type'}, 'type', 'type accessor is type');
is($accessors->{'name'}, 'name', 'name accessor is name');
is($accessors->{'description'}, 'description', 'description accessor is description');


## add a normal column, %col_info, and remove column to unconnected schema
$storage->_columns_to_add(['foo', 'bar' => {accessor => 'baz'}]);
$storage->_columns_to_remove(['name']);
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 6, 'added 2 columns and removes 1');
ok(exists $accessors->{'id'}, 'id accessor exists');
ok(exists $accessors->{'shopper'}, 'shopper accessor exists');
ok(exists $accessors->{'type'}, 'type accessor exists');
ok(!exists $accessors->{'name'}, 'name accessor was removed');
ok(exists $accessors->{'description'}, 'description accessor exists');
ok(exists $accessors->{'foo'}, 'foo accesso exists');
ok(exists $accessors->{'bar'}, 'bar accessor exists');
is($accessors->{'id'}, 'id', 'id accessor is id');
is($accessors->{'shopper'}, 'shopper', 'shopper accessor is shopper');
is($accessors->{'type'}, 'type', 'type accessor is type');
is($accessors->{'description'}, 'description', 'description accessor is description');
is($accessors->{'foo'}, 'foo', 'foo accessor is foo');
is($accessors->{'bar'}, 'baz', 'bar accessor is baz');
$storage->_columns_to_add(undef);
$storage->_columns_to_remove(undef);


## get normal columns from connected schema
my $schema = $storage->schema_instance;
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 5, 'got 5 columns from schema instance');
ok(exists $accessors->{'id'}, 'id accessor exists');
ok(exists $accessors->{'shopper'}, 'shopper accessor exists');
ok(exists $accessors->{'type'}, 'type accessor exists');
ok(exists $accessors->{'name'}, 'name accessor exists');
ok(exists $accessors->{'description'}, 'description accessor exists');
is($accessors->{'id'}, 'id', 'id accessor is id');
is($accessors->{'shopper'}, 'shopper', 'shopper accessor is shopper');
is($accessors->{'type'}, 'type', 'type accessor is type');
is($accessors->{'description'}, 'description', 'description accessor is description');


## get normal columns from connected schema w/accessor
$schema->source($storage->schema_source)->add_columns('custom' => {accessor => 'baz'});
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 6, 'add a column to schema instance');
ok(exists $accessors->{'id'}, 'id accessor exists');
ok(exists $accessors->{'shopper'}, 'shopper accessor exists');
ok(exists $accessors->{'type'}, 'type accessor exists');
ok(exists $accessors->{'name'}, 'name accessor exists');
ok(exists $accessors->{'description'}, 'description accessor exists');
ok(exists $accessors->{'custom'}, 'custom accessor exists');
is($accessors->{'id'}, 'id', 'id accessor is id');
is($accessors->{'shopper'}, 'shopper', 'shopper accessor is shopper');
is($accessors->{'type'}, 'type', 'type accessor is type');
is($accessors->{'description'}, 'description', 'description accessor is description');
is($accessors->{'custom'}, 'baz', 'custom accessor is baz');
