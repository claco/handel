#!perl -wT
# $Id: cart_save.t 4 2004-12-28 03:01:15Z claco $
use Test::More;
use lib 't/lib';
use Handel::TestHelper;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'SQLite not installed';
    } else {
        plan tests => 9;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/cart_save.db';
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


## test for Handel::Exception::Constraint for invalid type
{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');

    try {
        $cart->type('abc');
    } catch Handel::Exception::Constraint with {
        pass;
    } otherwise {
        fail;
    };
};


## Load a cart, save it and validate type
#{
    my $cart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($cart, 'Handel::Cart');
    is($cart->type, CART_TYPE_TEMP);

    $cart->save;

    my $recart = Handel::Cart->load({
        id => '11111111-1111-1111-1111-111111111111'
    });
    isa_ok($recart, 'Handel::Cart');
    is($cart->type, CART_TYPE_SAVED);
#};