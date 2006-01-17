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
        plan tests => 35;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:cart :returnas));
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
        my $dbfile  = "t/cart_destroy_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## Test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            $subclass->destroy(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## Destroy a single cart via instance
    {
        my $cart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->count, 1);
        is($cart->subtotal, 9.99);

        $cart->destroy;

        my $recart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });

        is($recart, 0);
    };


    ## Destroy multiple carts with wildcard filter
    {
        my $carts = $subclass->load({name => 'Cart%'}, RETURNAS_ITERATOR);
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 2);

        $subclass->destroy({
            name => 'Cart%'
        });

        $carts = $subclass->load({name => 'Cart%'}, RETURNAS_ITERATOR);
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 0);
    };

};
