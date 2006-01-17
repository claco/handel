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
        plan tests => 74;
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
        my $dbfile  = "t/cart_delete_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            $subclass->delete(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## Delete a single cart item contents and validate counts
    {
        my $cart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->count, 1);
        is($cart->subtotal, 9.99);

        is($cart->delete({sku => 'SKU3333'}), 1);
        is($cart->count, 0);
        is($cart->subtotal, 0);

        my $recart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0);
        is($recart->subtotal, 0.00);
    };


    ## Delete multiple cart item contents with wildcard filter and validate counts
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->count, 2);
        is($cart->subtotal, 5.55);

        ok($cart->delete({sku => 'SKU%'}));
        is($cart->count, 0);
        is($cart->subtotal, 0);

        my $recart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0);
        is($recart->subtotal, 0.00);
    };

};
