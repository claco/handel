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
        plan tests => 74;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/cart_load.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    Handel::TestHelper::executesql($db, $create);
    Handel::TestHelper::executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## test for Handel::Exception::Argument where first param is not a hashref
{
    try {
        my $cart = Handel::Cart->load(id => '1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## load a single cart returning a Handel::Cart object
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
};


## load a single cart returning a Handel::Iterator object
{
    my $iterator = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    }, 1);
    isa_ok($iterator, 'Handel::Iterator');
};


## load all carts for the shopper returning a Handel::Iterator object
{
    my $iterator = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($iterator, 'Handel::Iterator');
};


## load all carts into an array without a filter
{
    my @carts = Handel::Cart->load();
    is(scalar @carts, 3);

    my $cart1 = $carts[0];
    isa_ok($cart1, 'Handel::Cart');
    is($cart1->id, '11111111-1111-1111-1111-111111111111');
    is($cart1->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart1->type, CART_TYPE_TEMP);
    is($cart1->name, 'Cart 1');
    is($cart1->description, 'Test Temp Cart 1');
    is($cart1->count, 2);
    is($cart1->subtotal, 5.55);

    my $cart2 = $carts[1];
    isa_ok($cart2, 'Handel::Cart');
    is($cart2->id, '22222222-2222-2222-2222-222222222222');
    is($cart2->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart2->type, CART_TYPE_TEMP);
    is($cart2->name, 'Cart 2');
    is($cart2->description, 'Test Temp Cart 2');
    is($cart2->count, 1);
    is($cart2->subtotal, 9.99);

    my $cart3 = $carts[2];
    isa_ok($cart3, 'Handel::Cart');
    is($cart3->id, '33333333-3333-3333-3333-333333333333');
    is($cart3->shopper, '33333333-3333-3333-3333-333333333333');
    is($cart3->type, CART_TYPE_SAVED);
    is($cart3->name, 'Cart 3');
    is($cart3->description, 'Saved Cart 1');
    is($cart3->count, 2);
    is($cart3->subtotal, 45.51);
};


## load all carts into an array with a filter
{
    my @carts = Handel::Cart->load({
        id => '22222222-2222-2222-2222-222222222222',
        name => 'Cart 2'
    });
    is(scalar @carts, 1);

    my $cart = $carts[0];
    isa_ok($cart, 'Handel::Cart');
    is($cart->id, '22222222-2222-2222-2222-222222222222');
    is($cart->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart->type, CART_TYPE_TEMP);
    is($cart->name, 'Cart 2');
    is($cart->description, 'Test Temp Cart 2');
    is($cart->count, 1);
    is($cart->subtotal, 9.99);
};


## load all carts into an array with a wildcard filter
{
    my @carts = Handel::Cart->load({
        name => 'Cart %'
    });
    is(scalar @carts, 3);

    my $cart1 = $carts[0];
    isa_ok($cart1, 'Handel::Cart');
    is($cart1->id, '11111111-1111-1111-1111-111111111111');
    is($cart1->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart1->type, CART_TYPE_TEMP);
    is($cart1->name, 'Cart 1');
    is($cart1->description, 'Test Temp Cart 1');
    is($cart1->count, 2);
    is($cart1->subtotal, 5.55);

    my $cart2 = $carts[1];
    isa_ok($cart2, 'Handel::Cart');
    is($cart2->id, '22222222-2222-2222-2222-222222222222');
    is($cart2->shopper, '11111111-1111-1111-1111-111111111111');
    is($cart2->type, CART_TYPE_TEMP);
    is($cart2->name, 'Cart 2');
    is($cart2->description, 'Test Temp Cart 2');
    is($cart2->count, 1);
    is($cart2->subtotal, 9.99);

    my $cart3 = $carts[2];
    isa_ok($cart3, 'Handel::Cart');
    is($cart3->id, '33333333-3333-3333-3333-333333333333');
    is($cart3->shopper, '33333333-3333-3333-3333-333333333333');
    is($cart3->type, CART_TYPE_SAVED);
    is($cart3->name, 'Cart 3');
    is($cart3->description, 'Saved Cart 1');
    is($cart3->count, 2);
    is($cart3->subtotal, 45.51);
};


## load returns 0
{
    my $cart = Handel::Cart->load({
        id => 'notfound'
    });
    is($cart, 0);
};