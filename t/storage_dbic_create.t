#!perl -wT
# $Id$
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
        plan tests => 10;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    result_class    => 'GenericResult',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## create a new record
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 0, 'cart table empty');
my $result = $storage->create({
    id      => '11111111-1111-1111-1111-111111111111',
    shopper => '21111111-1111-1111-1111-111111111111'
});
isa_ok($result, $storage->result_class);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 1, 'added 1 cart');
is($result->{'storage_result'}->id, '11111111-1111-1111-1111-111111111111', 'id is set');
is($result->{'storage_result'}->shopper, '21111111-1111-1111-1111-111111111111', 'shopper is set');
is(refaddr $result->{'storage'}, refaddr $storage, 'result storae is original storage');


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->create;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('argument exception caught');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('other exception caught');
};


package GenericResult;
sub create_instance {
    return bless {storage_result => $_[1], storage => $_[2]}, $_[0];
};
1;
