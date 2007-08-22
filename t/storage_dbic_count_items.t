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
        plan tests => 9;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## count cart items
my $schema = $storage->schema_instance;
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
my $result = bless {'storage_result' => $cart}, 'GenericResult';
is($storage->count_items($result), 2, 'counted 2 items');


## throw exception if no result is passed
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->count_items;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('argument exception thrown');
    like(shift, qr/no result/i, 'no result in message');
} otherwise {
    fail('other exception caught');
};


## throw exception when adding an item to something with incorrect relationship
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->item_relationship('foo');
    $storage->count_items($result);

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('exception storage caught');
    like(shift, qr/no such relationship/i, 'no relationship in message');
} otherwise {
    fail('caught other exception');
};


## throw exception when adding an item with no defined relationship
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->item_relationship(undef);
    $storage->count_items($result);

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no item relationship defined/i, 'no relationship in message');
} otherwise {
    fail('caught other exception');
};


package GenericResult;
sub storage_result {return shift->{'storage_result'}};
1;
