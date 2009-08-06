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
        plan tests => 7;
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


## start w/ nothing
is($storage->constraints, undef, 'no constraints are defined');


## add constraint to unconnected schema
my $sub = sub{};
$storage->add_constraint('id', 'Check Id', $sub);
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub}}, 'constraints are set');


## throw exception when connected
my $schema = $storage->schema_instance;
is_deeply($schema->class($storage->schema_source)->constraints, {'id' => {'Check Id' => $sub}}, 'constraints are loaded');

try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->add_constraint('name', second => sub{});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/existing schema instance/i, 'existing schema instance in message');
} otherwise {
    fail('other exception thrown');
};
