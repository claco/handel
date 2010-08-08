#!perl -w
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
        plan tests => 332;
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


    ## restore saved cart appending items to current cart
    ## just for sanity sake, we're checking all cart and item values
    {
        # load the temp cart
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1, 'loaded 1 cart');

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, 'Cart 1', 'got name');
        is($cart->description, 'Test Temp Cart 1', 'got description');
        is($cart->count, 2, 'has 2 items');
        cmp_currency($cart->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom', 'got custom field');
        };

        my $items = $cart->items;
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2, 'loaded 2 items');

        my $item1 = $items->next;
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111', 'got item id');
        is($item1->cart, $cart->id, 'cart id is set');
        is($item1->sku, 'SKU1111', 'got sku');
        is($item1->quantity, 1, 'quantity is 1');
        cmp_currency($item1->price+0, 1.11, 'price is 1.11');
        is($item1->description, 'Line Item SKU 1', 'got description');
        cmp_currency($item1->total+0, 1.11, 'total is 1.11');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom', 'got custom field');
        };

        my $item2 = $items->next;
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item2->cart, $cart->id, 'cart id is set');
        is($item2->sku, 'SKU2222', 'got sku');
        is($item2->quantity, 2, 'quantiy is 2');
        cmp_currency($item2->price+0, 2.22, 'price is 2.22');
        is($item2->description, 'Line Item SKU 2', 'got description');
        cmp_currency($item2->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom', 'got custom field');
        };


        # restore the saved cart replacing the temp cart and verify the results
        $cart->restore({id => '33333333-3333-3333-3333-333333333333'},
            CART_MODE_APPEND);
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, 'Cart 1', 'got name');
        is($cart->description, 'Test Temp Cart 1', 'got description');
        is($cart->count, 4, 'has 4 items');
        cmp_currency($cart->subtotal+0, 51.06, 'subtotal is 51.06');

        my $items3 = $cart->items;
        isa_ok($items3, 'Handel::Iterator');
        is($items3->count, 4, 'loaded 4 items');

        my $item5 = $items3->next;
        isa_ok($item5, 'Handel::Cart::Item');
        isa_ok($item5, $itemclass);
        is($item5->id, '11111111-1111-1111-1111-111111111111', 'got item id');
        is($item5->cart, $cart->id, 'cart id is set');
        is($item5->sku, 'SKU1111', 'got sku');
        is($item5->quantity, 1, 'quantity is 1');
        cmp_currency($item5->price+0, 1.11, 'price is 1.11');
        is($item5->description, 'Line Item SKU 1', 'got description');
        cmp_currency($item5->total+0, 1.11, 'total is 1.11');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item5->custom, 'custom', 'got custom field');
        };

        my $item6 = $items3->next;
        isa_ok($item6, 'Handel::Cart::Item');
        isa_ok($item6, $itemclass);
        is($item6->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item6->cart, $cart->id, 'cart id is set');
        is($item6->sku, 'SKU2222', 'got sku');
        is($item6->quantity, 2, 'quantity is 2');
        cmp_currency($item6->price+0, 2.22, 'price is 2.22');
        is($item6->description, 'Line Item SKU 2', 'got description');
        cmp_currency($item6->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item6->custom, 'custom', 'got custom field');
        };

        my $item7 = $items3->next;
        isa_ok($item7, 'Handel::Cart::Item');
        isa_ok($item7, $itemclass);
        isnt($item7->id, '44444444-4444-4444-4444-444444444444', 'id is different');
        is($item7->cart, $cart->id, 'cart id is set');
        is($item7->sku, 'SKU4444', 'got sku');
        is($item7->quantity, 4, 'quantity is 4');
        cmp_currency($item7->price+0, 4.44, 'price is 4.44');
        is($item7->description, 'Line Item SKU 4', 'got description');
        cmp_currency($item7->total+0, 17.76, 'total is 17.76');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item7->custom, 'custom', 'got custom field');
        };

        my $item8 = $items3->next;
        isa_ok($item8, 'Handel::Cart::Item');
        isa_ok($item8, $itemclass);
        isnt($item8->id, '55555555-5555-5555-5555-555555555555', 'id is different');
        is($item8->cart, $cart->id, 'cart id is set');
        is($item8->sku, 'SKU1111', 'got sku');
        is($item8->quantity, 5, 'quantity is 5');
        cmp_currency($item8->price+0, 5.55, 'price is 5.55');
        is($item8->description, 'Line Item SKU 5', 'got description');
        cmp_currency($item8->total+0, 27.75, 'total is 27.75');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item7->custom, 'custom', 'got custom field');
        };


        # load the saved cart again
        my $sit2 = $subclass->search({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($sit2, 'Handel::Iterator');
        is($sit2, 1, 'loaded 1 cart');

        my $saved2 = $sit2->first;
        isa_ok($saved2, 'Handel::Cart');
        isa_ok($saved2, $subclass);
        is($saved2->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($saved2->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($saved2->type, CART_TYPE_SAVED, 'got saved type');
        is($saved2->name, 'Cart 3', 'got name');
        is($saved2->description, 'Saved Cart 1', 'got description');
        is($saved2->count, 2, 'has 2 items');
        cmp_currency($saved2->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($saved2->custom, 'custom', 'got custom field');
        };

        my $items4 = $saved2->items;
        isa_ok($items4, 'Handel::Iterator');
        is($items4->count, 2, 'loaded 2 items');

        my $item9 = $items4->next;
        isa_ok($item9, 'Handel::Cart::Item');
        isa_ok($item9, $itemclass);
        is($item9->id, '44444444-4444-4444-4444-444444444444', 'got item id');
        is($item9->cart, $saved2->id, 'cart id is set');
        is($item9->sku, 'SKU4444', 'got sku');
        is($item9->quantity, 4, 'quantity is 4');
        cmp_currency($item9->price+0, 4.44, 'price is 4.44');
        is($item9->description, 'Line Item SKU 4', 'got description');
        cmp_currency($item9->total+0, 17.76, 'total is 17.76');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item9->custom, 'custom', 'got custom field');
        };

        my $item10 = $items4->next;
        isa_ok($item10, 'Handel::Cart::Item');
        isa_ok($item10, $itemclass);
        is($item10->id, '55555555-5555-5555-5555-555555555555', 'got item id');
        is($item10->cart, $saved2->id, 'cart id is set');
        is($item10->sku, 'SKU1111', 'got sku');
        is($item10->quantity, 5, 'quantity is 5');
        cmp_currency($item10->price+0, 5.55, 'price is 5.55');
        is($item10->description, 'Line Item SKU 5', 'got description');
        cmp_currency($item10->total+0, 27.75, 'total is 27.75');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item10->custom, 'custom', 'got custom field');
        };
    };

};
