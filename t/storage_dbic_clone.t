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


## not a class method
try {
    local $ENV{'LANGUAGE'} = 'en';

    Handel::Storage::DBIC->clone;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/class method/i, 'class method in name');
} otherwise {
    fail('other exception caught');
};


## clone w/ disconnected schema
my $clone = $storage->clone;
is_deeply($storage, $clone, 'storage is a copy of clone');
isnt(refaddr $storage, refaddr $clone, 'clone is not the original');


## clone w/connected schema
my $schema = $storage->schema_instance;
is(refaddr $storage->_schema_instance, refaddr $schema, 'clone is a full copy');
my $cloned = $storage->clone;
isnt(refaddr $storage, refaddr $cloned, 'clone is not the original');
is($cloned->_schema_instance, undef, 'unset clone schema instance');
is(refaddr $storage->schema_instance, refaddr $schema, 'original schema in tact');

$storage->_schema_instance(undef);
is_deeply($storage, $cloned, 'cloned schema a copy when connected');
