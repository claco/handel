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
        plan tests => 262;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;

    ## load all carts and iterator all cart and all items
    {
        my $carts = $subclass->search;
        isa_ok($carts, 'Handel::Iterator');
        is($carts->count, 3, 'loaded 3 ');

        my $cart1 = $carts->next;
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart1->type, CART_TYPE_TEMP, 'got temp type');
        is($cart1->name, 'Cart 1', 'got name');
        is($cart1->description, 'Test Temp Cart 1', 'got description');
        is($cart1->count, 2, 'has 2 items');
        is($cart1->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom', 'got custom field');
        };

        my $items = $cart1->items;
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2, 'has 2 items');

        my $item1 = $items->next;
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111', 'got item id');
        is($item1->cart, $cart1->id, 'cart id is set');
        is($item1->sku, 'SKU1111', 'got sku');
        is($item1->quantity, 1, 'quantity is 1');
        is($item1->price+0, 1.11, 'price is 1.11');
        is($item1->description, 'Line Item SKU 1', 'got description');
        is($item1->total+0, 1.11, 'total is 1.11');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom', 'got custom field');
        };

        my $item2 = $items->next;
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item2->cart, $cart1->id, 'cart id is set');
        is($item2->sku, 'SKU2222', 'got sku');
        is($item2->quantity, 2, 'quantity is 2');
        is($item2->price+0, 2.22, 'price is 2.22');
        is($item2->description, 'Line Item SKU 2', 'got description');
        is($item2->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom', 'got custom field');
        };

        my $item3 = $items->next;
        is($item3, undef, 'no more items');

        my $cart2 = $carts->next;
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart2->type, CART_TYPE_TEMP, 'got temp type');
        is($cart2->name, 'Cart 2', 'got name');
        is($cart2->description, 'Test Temp Cart 2', 'got description');
        is($cart2->count, 1, 'has 1 item');
        is($cart2->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom', 'got custom field');
        };

        my $items2 = $cart2->items;
        isa_ok($items2, 'Handel::Iterator');
        is($items2->count, 1, 'has 1 item');

        my $item4 = $items2->next;
        isa_ok($item4, 'Handel::Cart::Item');
        isa_ok($item4, $itemclass);
        is($item4->id, '33333333-3333-3333-3333-333333333333', 'got item id');
        is($item4->cart, $cart2->id, 'cart id is set');
        is($item4->sku, 'SKU3333', 'got sku');
        is($item4->quantity, 3, 'quantity is 3');
        is($item4->price+0, 3.33, 'price is 3.33');
        is($item4->description, 'Line Item SKU 3', 'got description');
        is($item4->total+0, 9.99, 'total is 9.99');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item4->custom, 'custom', 'got custom field');
        };

        my $cart3 = $carts->next;
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($cart3->type, CART_TYPE_SAVED, 'got saved type');
        is($cart3->name, 'Cart 3', 'got name');
        is($cart3->description, 'Saved Cart 1', 'got description');
        is($cart3->count, 2, 'has 2 items');
        is($cart3->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom', 'got custom field');
        };

        my $items3 = $cart3->items;
        isa_ok($items3, 'Handel::Iterator');
        is($items3->count, 2, 'has 2 items');

        my $item5 = $items3->next;
        isa_ok($item5, 'Handel::Cart::Item');
        isa_ok($item5, $itemclass);
        is($item5->id, '44444444-4444-4444-4444-444444444444', 'got item id');
        is($item5->cart, $cart3->id, 'cart id is set');
        is($item5->sku, 'SKU4444', 'got sku');
        is($item5->quantity, 4, 'quantity is 4');
        is($item5->price+0, 4.44, 'prive is 4.44');
        is($item5->description, 'Line Item SKU 4', 'got description');
        is($item5->total+0, 17.76, 'total is 17.76');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item5->custom, 'custom', 'got custom field');
        };

        my $item6 = $items3->next;
        isa_ok($item6, 'Handel::Cart::Item');
        isa_ok($item6, $itemclass);
        is($item6->id, '55555555-5555-5555-5555-555555555555', 'got item id');
        is($item6->cart, $cart3->id, 'cart id is set');
        is($item6->sku, 'SKU1111', 'got sku');
        is($item6->quantity, 5, 'quantity is 5');
        is($item6->price+0, 5.55, 'price is 5.55');
        is($item6->description, 'Line Item SKU 5', 'got sku');
        is($item6->total+0, 27.75, 'titak us 27.75');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item6->custom, 'custom', 'got custom field');
        };

        my $cart4 = $carts->next;
        is($cart4, undef, 'no carts left');
    };

};
