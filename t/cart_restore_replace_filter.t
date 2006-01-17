#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 261;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/cart_restore_replace_filter_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## restore saved cart replacing current cart
    ## just for sanity sake, we're checking all cart and item values
    {
        # load the temp cart
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $items = $cart->items(undef, 1);
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2);

        my $item1 = $items->next;
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        is($item1->price, 1.11);
        is($item1->description, 'Line Item SKU 1');
        is($item1->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items->next;
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        is($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        is($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };

        # restore te saved cart replacing the temp cart and verify the results
        $cart->restore({id => '33333333-3333-3333-3333-333333333333'},
            CART_MODE_REPLACE);
        is($cart->name, 'Cart 3');
        is($cart->description, 'Saved Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 45.51);

        my $items3 = $cart->items(undef, 1);
        isa_ok($items3, 'Handel::Iterator');
        is($items3->count, 2);

        my $item5 = $items3->next;
        isa_ok($item5, 'Handel::Cart::Item');
        isa_ok($item5, $itemclass);
        isnt($item5->id, '44444444-4444-4444-4444-444444444444');
        is($item5->cart, $cart->id);
        is($item5->sku, 'SKU4444');
        is($item5->quantity, 4);
        is($item5->price, 4.44);
        is($item5->description, 'Line Item SKU 4');
        is($item5->total, 17.76);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item5->custom, 'custom');
        };

        my $item6 = $items3->next;
        isa_ok($item6, 'Handel::Cart::Item');
        isa_ok($item6, $itemclass);
        isnt($item6->id, '55555555-5555-5555-5555-555555555555');
        is($item6->cart, $cart->id);
        is($item6->sku, 'SKU1111');
        is($item6->quantity, 5);
        is($item6->price, 5.55);
        is($item6->description, 'Line Item SKU 5');
        is($item6->total, 27.75);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item6->custom, 'custom');
        };


        # load the saved cart again
        my $saved2 = $subclass->load({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($saved2, 'Handel::Cart');
        isa_ok($saved2, $subclass);
        is($saved2->id, '33333333-3333-3333-3333-333333333333');
        is($saved2->shopper, '33333333-3333-3333-3333-333333333333');
        is($saved2->type, CART_TYPE_SAVED);
        is($saved2->name, 'Cart 3');
        is($saved2->description, 'Saved Cart 1');
        is($saved2->count, 2);
        is($saved2->subtotal, 45.51);
        if ($subclass ne 'Handel::Cart') {
            is($saved2->custom, 'custom');
        };

        my $items4 = $saved2->items(undef, 1);
        isa_ok($items4, 'Handel::Iterator');
        is($items4->count, 2);

        my $item7 = $items4->next;
        isa_ok($item7, 'Handel::Cart::Item');
        isa_ok($item7, $itemclass);
        is($item7->id, '44444444-4444-4444-4444-444444444444');
        is($item7->cart, $saved2->id);
        is($item7->sku, 'SKU4444');
        is($item7->quantity, 4);
        is($item7->price, 4.44);
        is($item7->description, 'Line Item SKU 4');
        is($item7->total, 17.76);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item7->custom, 'custom');
        };

        my $item8 = $items4->next;
        isa_ok($item8, 'Handel::Cart::Item');
        isa_ok($item8, $itemclass);
        is($item8->id, '55555555-5555-5555-5555-555555555555');
        is($item8->cart, $saved2->id);
        is($item8->sku, 'SKU1111');
        is($item8->quantity, 5);
        is($item8->price, 5.55);
        is($item8->description, 'Line Item SKU 5');
        is($item8->total, 27.75);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item8->custom, 'custom');
        };
    };

};
