#!perl -wT
# $Id: cart_delete.t 4 2004-12-28 03:01:15Z claco $
use Test::More;
use lib 't/lib';
use Handel::TestHelper;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'SQLite not installed';
    } else {
        plan tests => 22;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/cart_delete.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    Handel::TestHelper::executesql($db, $create);
    Handel::TestHelper::executesql($db, $data);

    local $^W = 0;
    Handel::Cart->connection($db);
    Handel::Cart::Item->connection($db);
};


## test for Handel::Exception::Argument where first param is not a hashref
{
    try {
        Handel::Cart->delete(id => '1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Delete a single cart item contents and validate counts
{
    my $cart = Handel::Cart->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->count, 1);
    is($cart->subtotal, 9.99);

    is($cart->delete({sku => 'SKU3333'}), 1);
    is($cart->count, 0);
    is($cart->subtotal, 0);

    my $recart = Handel::Cart->load({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($recart, 'Handel::Cart');
    is($cart->count, 0);
    is($cart->subtotal, 0.00);
};


## Delete multiple cart item contents with wildcard filter and validate counts
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->count, 2);
    is($cart->subtotal, 5.55);

    ok($cart->delete({sku => 'SKU%'}));
    is($cart->count, 0);
    is($cart->subtotal, 0);

    my $recart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($recart, 'Handel::Cart');
    is($cart->count, 0);
    is($cart->subtotal, 0.00);
};