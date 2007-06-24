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
        plan tests => 11;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## get primary columns on unconnected schema
is($storage->_primary_columns, undef, 'no primary columns defined');
is_deeply([$storage->primary_columns], [qw/id/], 'return DBIC primary keys');


## set primary columns on unconnected storage
$storage->primary_columns(qw/id shopper/);
is_deeply($storage->_primary_columns, [qw/id shopper/], 'storage primary columns');
is_deeply([$storage->primary_columns], [qw/id shopper/], 'returned primary columns');
is_deeply([$storage->schema_class->source($storage->schema_source)->primary_columns], [qw/id/], 'leave schema alone until connected');
$storage->_primary_columns(undef);


## get/set primary columns from schema instance
my $schema = $storage->schema_instance;
is_deeply([$storage->primary_columns], [qw/id/], 'return DBIC primary key');
is_deeply([$schema->source($storage->schema_source)->primary_columns], [qw/id/], 'return DBIC primary key');
$storage->primary_columns(qw/id shopper/);
is_deeply([$storage->primary_columns], [qw/id shopper/], 'added primarys columns');
is_deeply([$schema->source($storage->schema_source)->primary_columns], [qw/id shopper/], 'added primary columns to source');
