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
        plan tests => 17;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $schema = Handel::Test->init_schema;
my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        $schema->dsn
    ]
});


## delete all items w/ no params
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3, 'start with 3 carts');
is($storage->schema_instance->resultset('Items')->search->count, 5, 'start with 5 items');
ok($storage->delete, 'delete all');
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 0, 'no carts');
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 0, 'no items');


## delete all items w/ CDBI wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3, 'start with 3 carts');
is($storage->schema_instance->resultset('Items')->search->count, 5, 'start with 5 items');
ok($storage->delete({ description => 'Test%'}), 'delete using CDBI wildcards');
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 1, '1 cart left');
is($storage->schema_instance->resultset('Items')->search->count, 2, '2 items left');


## delete all items w/ DBIC wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3, 'start with 3 carts');
is($storage->schema_instance->resultset('Items')->search->count, 5, 'start with 5 items');
ok($storage->delete({ description => {like => 'Test%'}}), 'delete using DBIC wildcards');
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 1, '1 cart left');
is($storage->schema_instance->resultset('Items')->search->count, 2, '2 items left');
