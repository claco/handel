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
        plan tests => 36;
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


## migrate wildcards
is($storage->_migrate_wildcards, undef, 'storage is undefined');
is_deeply($storage->_migrate_wildcards([qw/a b c/]), [qw/a b c/], 'migrate nothing with non hashes');
is_deeply($storage->_migrate_wildcards({ a => 'b'}), {a => 'b'}, 'change nothing if no wilcards are present');



## get all results in list
{
    my @results = $storage->search;
    is(@results, 3, 'loaded 3 carts');
    foreach my $result (@results) {
        isa_ok($result, $storage->result_class);
        is(refaddr $result->storage, refaddr $storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'result class is the composed style');
    };
};


## get all results as an iterator
{
    my $results = $storage->search;
    is($results->count, 3, 'return 3 carts');
    isa_ok($results, $storage->iterator_class);
    while (my $result = $results->next) {
        isa_ok($result, $storage->result_class);
        is(refaddr $result->storage, refaddr $storage, 'result storage is original storage');
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'result class is the composed style');
    };
};


## filter results using CDBI wildcards
{
    my $carts = $storage->search({ id => '1111%'});
    is($carts->count, 1, 'loaded 1 cart');
    my $result = $carts->first;
    isa_ok($result, $storage->result_class);
    is(refaddr $result->storage, refaddr $storage, 'result storage is original storage');
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'result class is the composed style');
    is($result->id, '11111111-1111-1111-1111-111111111111', 'id matches requested cart');
};


## filter results using DBIC wildcards
{
    my $carts = $storage->search({ id => {like => '1111%'}});
    is($carts->count, 1, 'loaded 1 cart');
    my $result = $carts->first;
    isa_ok($result, $storage->result_class);
    is(refaddr $result->storage, refaddr $storage, 'result storage is original storage');
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'result class is the composed style');
    is($result->id, '11111111-1111-1111-1111-111111111111', 'id matches request cart');
};
