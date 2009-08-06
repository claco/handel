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
        plan tests => 6;
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
is($storage->constraints, undef, 'constraints are undefined');

my $sub = {};
$storage->constraints({
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    }
});


## remove constraint from unconnected schema
$storage->remove_constraint('id', 'Check Id');
is_deeply($storage->constraints, {'id' => {'Check It Again' => $sub}}, 'constraints was removed');


## throw exception when connected
my $schema = $storage->schema_instance;

try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->remove_constraint('name', 'Check Name');

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/existing schema instance/i, 'existing schema instance in message');
} otherwise {
    fail('caught other exception');
};
