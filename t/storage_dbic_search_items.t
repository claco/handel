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
        plan tests => 47;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class       => 'Handel::Cart::Schema',
    schema_source      => 'Carts',
    item_storage_class => 'Handel::Storage::DBIC::Cart::Item',
    connection_info    => [
        Handel::Test->init_schema->dsn
    ]
});


my $schema = $storage->schema_instance;
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
my $result = bless {'storage_result' => $cart}, 'GenericResult';


## get the items via items
{
    my @results = $storage->result_class->create_instance($cart, $storage)->items;
    foreach my $result (@results) {
        isa_ok($result, $storage->item_storage->result_class);
        is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    };
};


## get the items via items via instance
{
    my $result_class = bless {}, $storage->result_class;
    my @results = $result_class->create_instance($cart, $storage)->items;
    foreach my $result (@results) {
        isa_ok($result, $storage->item_storage->result_class);
        is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    };
};


## get all results in list
{
    my @results = $storage->search_items($result);
    is(@results, 2, 'loaded 2 items');
    foreach my $result (@results) {
        isa_ok($result, $storage->item_storage->result_class);
        is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    };
};


## get all results as an iterator
{
    my $results = $storage->search_items($result);
    is($results->count, 2, 'loaded 2 items');
    isa_ok($results, $storage->iterator_class);
    while (my $result = $results->next) {
        isa_ok($result, $storage->item_storage->result_class);
        is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    };
};


## filter results using CDBI wildcards
{
    my $items = $storage->search_items($result, { id => '1111%'});
    is($items->count, 1, 'loaded 2 items');
    my $result = $items->first;
    isa_ok($result, $storage->item_storage->result_class);
    is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    is($result->id, '11111111-1111-1111-1111-111111111111', 'got id');
};


## filter results using DBIC wildcards
{
    my $items = $storage->search_items($result, { id => {like => '1111%'}});
    is($items->count, 1, 'loaded 1 item');
    my $result = $items->first;
    isa_ok($result, $storage->result_class);
    is(refaddr $result->result_source->{'__handel_storage'}, refaddr $result->storage, 'result storage is original storage');
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is composed class style');
    is($result->id, '11111111-1111-1111-1111-111111111111', 'got id');
};


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->search_items;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/no result/i, 'no result in message');
} otherwise {
    fail('other exception caught');
};


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->search_items($result, []);

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass('caught argument exception');
    like(shift, qr/not a HASH/i, 'not a hash in message');
} otherwise {
    fail('other exception caught');
};


## throw exception when searching to something with incorrect relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship('foo');
    $storage->search_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no such relationship/i, 'no relationship in message');
} otherwise {
    fail('other exception caught');
};


## throw exception when adding an item with no defined relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship(undef);
    $storage->search_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/no item relationship defined/i, 'no relationship in message');
} otherwise {
    fail('other exception caught');
};


package GenericResult;
sub storage_result {return shift->{'storage_result'}};
1;
