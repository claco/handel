#!perl -wT
# $Id$
use Test::More;
use lib 't/lib';
use Handel::TestHelper;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'SQLite not installed';
    } else {
        plan tests => 82;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/cart_items.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    Handel::TestHelper::executesql($db, $create);
    Handel::TestHelper::executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## load multiple item Handel::Cart object and get items array
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my @items = $cart->items;
    is(scalar @items, $cart->count);

    my $item1 = $items[0];
    isa_ok($item1, 'Handel::Cart::Item');
    is($item1->id, '11111111-1111-1111-1111-111111111111');
    is($item1->cart, $cart->id);
    is($item1->sku, 'SKU1111');
    is($item1->quantity, 1);
    is($item1->price, 1.11);
    is($item1->description, 'Line Item SKU 1');
    is($item1->total, 1.11);

    my $item2 = $items[1];
    isa_ok($item2, 'Handel::Cart::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->cart, $cart->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
    is($item2->total, 4.44);
};


## load multiple item Handel::Cart object and get items Iterator
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my $items = $cart->items;
    isa_ok($items, 'Handel::Iterator');
    is($items->count, 2);
};


## load multiple item Handel::Cart object and get filter single item
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my $item2 = $cart->items({sku => 'SKU2222'});
    isa_ok($item2, 'Handel::Cart::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->cart, $cart->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
    is($item2->total, 4.44);
};


## load multiple item Handel::Cart object and get filter single item to Iterator
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my $iterator = $cart->items({sku => 'SKU2222'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
};


## load multiple item Handel::Cart object and get wilcard filter to Iterator
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my $iterator = $cart->items({sku => 'SKU%'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
    is($iterator, 2);
};


## load multiple item Handel::Cart object and get filter bogus item to Iterator
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '11111111-1111-1111-1111-111111111111');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    my $iterator = $cart->items({sku => 'notfound'}, 1);
    isa_ok($iterator, 'Handel::Iterator');
};
