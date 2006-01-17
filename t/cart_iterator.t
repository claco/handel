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
        plan tests => 262;
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
        my $dbfile  = 't/cart_iterator.db';
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## load all carts and iterator all cart and all items
    {
        my $carts = $subclass->load(undef, 1);
        isa_ok($carts, 'Handel::Iterator');
        is($carts->count, 3);

        my $cart1 = $carts->next;
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart1->type, CART_TYPE_TEMP);
        is($cart1->name, 'Cart 1');
        is($cart1->description, 'Test Temp Cart 1');
        is($cart1->count, 2);
        is($cart1->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom');
        };

        my $items = $cart1->items(undef, 1);
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2);

        my $item1 = $items->next;
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart1->id);
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
        is($item2->cart, $cart1->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        is($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        is($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };

        my $item3 = $items->next;
        is($item3, undef);

        my $cart2 = $carts->next;
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart2->type, CART_TYPE_TEMP);
        is($cart2->name, 'Cart 2');
        is($cart2->description, 'Test Temp Cart 2');
        is($cart2->count, 1);
        is($cart2->subtotal, 9.99);
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom');
        };

        my $items2 = $cart2->items(undef, 1);
        isa_ok($items2, 'Handel::Iterator');
        is($items2->count, 1);

        my $item4 = $items2->next;
        isa_ok($item4, 'Handel::Cart::Item');
        isa_ok($item4, $itemclass);
        is($item4->id, '33333333-3333-3333-3333-333333333333');
        is($item4->cart, $cart2->id);
        is($item4->sku, 'SKU3333');
        is($item4->quantity, 3);
        is($item4->price, 3.33);
        is($item4->description, 'Line Item SKU 3');
        is($item4->total, 9.99);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item4->custom, 'custom');
        };

        my $cart3 = $carts->next;
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333');
        is($cart3->type, CART_TYPE_SAVED);
        is($cart3->name, 'Cart 3');
        is($cart3->description, 'Saved Cart 1');
        is($cart3->count, 2);
        is($cart3->subtotal, 45.51);
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom');
        };

        my $items3 = $cart3->items(undef, 1);
        isa_ok($items3, 'Handel::Iterator');
        is($items3->count, 2);

        my $item5 = $items3->next;
        isa_ok($item5, 'Handel::Cart::Item');
        isa_ok($item5, $itemclass);
        is($item5->id, '44444444-4444-4444-4444-444444444444');
        is($item5->cart, $cart3->id);
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
        is($item6->id, '55555555-5555-5555-5555-555555555555');
        is($item6->cart, $cart3->id);
        is($item6->sku, 'SKU1111');
        is($item6->quantity, 5);
        is($item6->price, 5.55);
        is($item6->description, 'Line Item SKU 5');
        is($item6->total, 27.75);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item6->custom, 'custom');
        };

        my $cart4 = $carts->next;
        is($cart4, undef);
    };

};
