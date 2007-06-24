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
        plan tests => 21;
    };

    use_ok('Handel::Storage::DBIC');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## We have nothing
is($storage->_columns_to_add, undef, 'no columns added');


## Add generic without schema instance adds to collection
$storage->add_columns(qw/foo/);
is($storage->_schema_instance, undef, 'no schema instance');
is_deeply($storage->_columns_to_add, [qw/foo/], 'added foo');
$storage->add_columns(qw/bar/);
is_deeply($storage->_columns_to_add, [qw/foo bar/], 'appended bar');
$storage->_columns_to_add(undef);


## Add w/info without schema instance
$storage->add_columns(bar => {accessor => 'baz'});
is($storage->_schema_instance, undef, 'unset schema instance');
is_deeply($storage->_columns_to_add, [bar => {accessor => 'baz'}], 'added column w/ accessor');
$storage->_columns_to_add(undef);


## Add to a connected schema
my $schema = $storage->schema_instance;
ok(!$schema->source($storage->schema_source)->has_column('custom'), 'source has no custom column');
ok(!$schema->class($storage->schema_source)->can('custom'), 'source has no accessor for custom');
$storage->add_columns('custom');
is_deeply($storage->_columns_to_add, [qw/custom/], 'added column');
ok($schema->source($storage->schema_source)->has_column('custom'), 'custom column added');
ok($schema->class($storage->schema_source)->can('custom'), 'custom accessor added');
$storage->_columns_to_add(undef);
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
ok($cart->can('custom'), 'result has custom method');
is($cart->custom, 'custom', 'got custom value');
$schema->source($storage->schema_source)->remove_columns('custom');


## Add w/info to a connected schema
ok(!$schema->source($storage->schema_source)->has_column('custom'), 'source has no custom');
ok(!$schema->class($storage->schema_source)->can('baz'), 'source has no accessor');
$storage->add_columns(custom => {accessor => 'baz'});
is_deeply($storage->_columns_to_add, [custom => {accessor => 'baz'}], 'added custom columnd w/ accessor');
ok($schema->source($storage->schema_source)->has_column('custom'), 'cutom column added');
ok($schema->class($storage->schema_source)->can('baz'), 'custom column accessor added');
$cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
ok($cart->can('baz'), 'cart has custom accessor');
is($cart->baz, 'custom', 'got custom value');
