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
        plan tests => 8;
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
    },
    name => {
        'Check Name' => $sub,
        'Check Name Again' => $sub
    }
});


## remove constraint from unconnected schema
$storage->remove_constraints('name');
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub, 'Check It Again' => $sub}}, 'constraints were stored');


## throw exception when no column is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraints;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('argument exception caught');
    like(shift, qr/no column/i, 'no column in message');
} otherwise {
    fail('other exception caught');
};

## throw exception when connected
my $schema = $storage->schema_instance;

try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraints('name');

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/existing schema instance/i, 'existing schema instance in message');
} otherwise {
    fail('other exception caught');
};
