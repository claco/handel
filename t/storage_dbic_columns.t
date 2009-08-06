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
        plan tests => 3;
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


## get columns from unconnected schema (really column accessors keys
is_deeply([sort $storage->columns], [qw/description id name shopper type/], 'received expected columns');


## get columns from connected schema
my $schema = $storage->schema_instance;
is_deeply([sort $storage->columns], [sort $schema->source($storage->schema_source)->columns], 'received expected columns from schema instance');
