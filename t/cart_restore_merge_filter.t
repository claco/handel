#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'SQLite not installed';
    } else {
        plan tests => 86;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/cart_restore_merge_filter.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    Handel::TestHelper::executesql($db, $create);
    Handel::TestHelper::executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## restore saved cart appending items to current cart
## just for sanity sake, we're checking all cart and item values
{
    # load the temp cart
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

    my $items = $cart->items(undef, 1);
    isa_ok($items, 'Handel::Iterator');
    is($items->count, 2);

    my $item1 = $items->next;
    isa_ok($item1, 'Handel::Cart::Item');
    is($item1->id, '11111111-1111-1111-1111-111111111111');
    is($item1->cart, $cart->id);
    is($item1->sku, 'SKU1111');
    is($item1->quantity, 1);
    is($item1->price, 1.11);
    is($item1->description, 'Line Item SKU 1');
    is($item1->total, 1.11);

    my $item2 = $items->next;
    isa_ok($item2, 'Handel::Cart::Item');
    is($item2->id, '22222222-2222-2222-2222-222222222222');
    is($item2->cart, $cart->id);
    is($item2->sku, 'SKU2222');
    is($item2->quantity, 2);
    is($item2->price, 2.22);
    is($item2->description, 'Line Item SKU 2');
    is($item2->total, 4.44);


    # restore the saved cart merging with the temp cart and verify the results
    $cart->restore({id => '33333333-3333-3333-3333-333333333333'},
        CART_MODE_MERGE);
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 1');
    is($cart->description, 'Test Temp Cart 1');
    is($cart->count, 3);
    is($cart->subtotal, 28.86);

    my $items3 = $cart->items(undef, 1);
    isa_ok($items3, 'Handel::Iterator');
    is($items3->count, 3);

    my $item5 = $items3->next;
    isa_ok($item5, 'Handel::Cart::Item');
    is($item5->id, '11111111-1111-1111-1111-111111111111');
    is($item5->cart, $cart->id);
    is($item5->sku, 'SKU1111');
    is($item5->quantity, 6);
    is($item5->price, 1.11);
    is($item5->description, 'Line Item SKU 1');
    is($item5->total, 6.66);

    my $item6 = $items3->next;
    isa_ok($item6, 'Handel::Cart::Item');
    is($item6->id, '22222222-2222-2222-2222-222222222222');
    is($item6->cart, $cart->id);
    is($item6->sku, 'SKU2222');
    is($item6->quantity, 2);
    is($item6->price, 2.22);
    is($item6->description, 'Line Item SKU 2');
    is($item6->total, 4.44);

    my $item7 = $items3->next;
    isa_ok($item7, 'Handel::Cart::Item');
    isnt($item7->id, '44444444-4444-4444-4444-444444444444');
    is($item7->cart, $cart->id);
    is($item7->sku, 'SKU4444');
    is($item7->quantity, 4);
    is($item7->price, 4.44);
    is($item7->description, 'Line Item SKU 4');
    is($item7->total, 17.76);


    # load the saved cart again
    my $saved2 = Handel::Cart->load({
        id => '33333333-3333-3333-3333-333333333333'
    });
    isa_ok($saved2, 'Handel::Cart');
    is($saved2->id, '33333333-3333-3333-3333-333333333333');
    is($saved2->shopper, '33333333-3333-3333-3333-333333333333');
    is($saved2->type, CART_TYPE_SAVED);
    is($saved2->name, 'Cart 3');
    is($saved2->description, 'Saved Cart 1');
    is($saved2->count, 2);
    is($saved2->subtotal, 45.51);

    my $items4 = $saved2->items(undef, 1);
    isa_ok($items4, 'Handel::Iterator');
    is($items4->count, 2);

    my $item9 = $items4->next;
    isa_ok($item9, 'Handel::Cart::Item');
    is($item9->id, '44444444-4444-4444-4444-444444444444');
    is($item9->cart, $saved2->id);
    is($item9->sku, 'SKU4444');
    is($item9->quantity, 4);
    is($item9->price, 4.44);
    is($item9->description, 'Line Item SKU 4');
    is($item9->total, 17.76);

    my $item10 = $items4->next;
    isa_ok($item10, 'Handel::Cart::Item');
    is($item10->id, '55555555-5555-5555-5555-555555555555');
    is($item10->cart, $saved2->id);
    is($item10->sku, 'SKU1111');
    is($item10->quantity, 5);
    is($item10->price, 5.55);
    is($item10->description, 'Line Item SKU 5');
    is($item10->total, 27.75);
}
