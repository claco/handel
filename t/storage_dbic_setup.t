#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 15;

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order::Schema');
};

my $storage = Handel::Storage::DBIC->new;
$storage->setup({
    connection_info      => ['mydsn'],
    constraints_class    => 'Handel::Base',
    default_values_class => 'Handel::Base',
    item_relationship    => 'myitems',
    schema_class         => 'Handel::Base',
    schema_instance      => Handel::Order::Schema->connect,
    schema_source        => 'Orders',
    table_name           => 'mytable',
    validation_class     => 'Handel::Base'
});

is_deeply($storage->connection_info, ['mydsn'], 'connection was set');
is($storage->constraints_class, 'Handel::Base', 'constraints class was set');
is($storage->default_values_class, 'Handel::Base', 'default values class was set');
is($storage->item_relationship, 'myitems', 'item relationship was set');
is($storage->schema_class, 'Handel::Order::Schema', 'schema class was set');
is($storage->schema_source, 'Orders', 'schema source was set');
is($storage->table_name, 'mytable', 'table name was set');
is($storage->validation_class, 'Handel::Base', 'validation class was set');


## throw exception if no result is passed
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->setup;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('argument exception caught');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('other exception caught');
};


## throw exception if no result is passed
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->setup({});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/schema instance/i, 'existing schema instance in message');
} otherwise {
    fail('other exception thrown');
};
