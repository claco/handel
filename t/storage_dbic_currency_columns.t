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
        plan tests => 34;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $currency_columns = [qw/name/];
my $storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Carts',
    connection_info  => [Handel::Test->init_schema(no_populate => 1)->dsn],
    currency_columns => $currency_columns
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply([$storage->currency_columns], $currency_columns, 'currency columns were set');

    $storage->currency_columns(qw/description/);
    is_deeply([$storage->currency_columns], [qw/description/], 'got same columns');

    ## ignored. just a safety check that should never make it past the
    ## currency_columns checks -> columns
    push @{$storage->_currency_columns}, 'nonexistant';

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart = $schema->resultset('Carts')->create({
        id => 1,
        shopper => 2,
        name => 'test',
        description => '23'
    });
    is($cart->name, 'test', 'got name');
    is($cart->description, '23.00 USD', 'got descrption');
    isa_ok($cart->description, 'Handel::Currency', 'description is a currency object');

    ## reset it all, and try a custom currency class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef, 'unset schema instance');

    $storage->currency_class('Handel::Subclassing::Currency');
    is($storage->currency_class, 'Handel::Subclassing::Currency', 'currency class was set');
    is(Handel::Storage->currency_class, 'Handel::Currency', 'original currency class is ok');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');

    my $new_cart = $new_schema->resultset('Carts')->create({
        id => 2,
        shopper => 2,
        name => 'foo',
        description => '54'
    });
    is($new_cart->name, 'foo', 'got name');
    is($new_cart->description, '54.00 USD', 'got description');
    isa_ok($new_cart->description, 'Handel::Subclassing::Currency', 'description is a currency object');
};


## do the item_storage currency_columns too
{
    my $currency_columns = [qw/sku/];

    $storage->schema_instance(undef);
    my $item_storage = Handel::Storage::DBIC->new({
        schema_class     => 'Handel::Cart::Schema',
        schema_source    => 'Items',
        currency_code    => 'USD',
        currency_columns => $currency_columns
    });
    $storage->item_storage($item_storage);

    is_deeply([$storage->item_storage->currency_columns], $currency_columns, 'currency columns were set');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    ## ignored. just a safety check that should never make it past the
    ## currency_columns checks -> columns
    push @{$item_storage->_currency_columns}, 'nonexistant';

    my $item = $schema->resultset('Items')->create({
        id => 1,
        cart => 1,
        sku => 5.43,
        price => 1.23
    });
    is($item->sku+0, 5.43, 'got sku');
    isa_ok($item->sku, 'Handel::Currency', 'sku is a currency column');
    is($item->sku->code, 'USD', 'code set from code column');
};


## do the item_storage currency_columns too
{
    $storage->schema_instance(undef);
    my $item_storage = Handel::Storage::DBIC->new({
        schema_class     => 'Handel::Cart::Schema',
        schema_source    => 'Items',
        currency_columns => ['price'],
        currency_code_column  => 'sku',
        table_name       => 'cart_items'
    });
    $storage->item_storage($item_storage);

    is($storage->item_storage->currency_code, undef, 'unset schema instance');

    ## ignored. just a safety check that should never make it past the
    ## currency_columns checks -> columns
    push @{$item_storage->_currency_columns}, 'nonexistant';

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $item = $schema->resultset('Items')->create({
        id => 2,
        cart => 1,
        sku => 'CAD',
        price => 1.23
    });
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, 'CAD', 'code set from code column');
    is($item->price+0, 1.23, 'got price');
    is($item->price->format, 'FMT_STANDARD', 'got default format');
    is($item->price->stringify, '1.23 CAD', 'got default format');

    $item = $schema->resultset('Items')->create({
        id => 3,
        cart => 1,
        sku => '0',
        price => 1.24
    });
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, 'USD', 'no code is set');
    is($item->price+0, 1.24, 'got price');
    is($item->price->format, 'FMT_STANDARD', 'got default format');
    is($item->price->stringify, '1.24 USD', 'got default format');
    $item->price(Handel::Currency->new(2.43));
    $item->update;
    is($item->price+0, 2.43, 'got new price object');
};
