#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    plan skip_all => 'DBD::SQLite not installed' if($@);

    eval 'use Class::DBI 3.0.8';
    plan skip_all => 'Class::DBI 3.0.8 or greater required' if($@);

    plan tests => 24;

    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Subclassing::Item');
};


## Setup SQLite DB for tests
{
    my $dbfile  = 't/subclassing.db';
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    executesql($db, $create);
    executesql($db, $data);

    local $^W = 0;
    Handel::DBI->connection($db);
};


## Create a custom cart that still returns Handel::Cart::Item
{
    my $cart = Handel::Subclassing::CartOnly->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($cart, 'Handel::Subclassing::CartOnly');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom');

    my $item = $cart->add({
        sku => 'SKU123'
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item');
    ok(!$item->can('custom'));
};


## Create a custom cart that still returns custom items
{
    my $cart = Handel::Subclassing::Cart->new({
        id => Handel->newuuid,
        custom => 'custom'
    });

    isa_ok($cart, 'Handel::Subclassing::Cart');
    isa_ok($cart, 'Handel::Cart');
    can_ok($cart, 'custom');
    is($cart->custom, 'custom');

    my $item = $cart->add({
        sku    => 'SKU123',
        custom => 'custom'
    });

    isa_ok($item, 'Handel::Cart::Item');
    isa_ok($item, 'Handel::Subclassing::Item');
    is(ref $item, 'Handel::Subclassing::Item');
    can_ok($item, 'custom');
    is($cart->custom, 'custom');
};


## Make sure the old stuff works like normal
{
    my $cart = Handel::Cart->new({
        id => Handel->newuuid
    });

    isa_ok($cart, 'Handel::Cart');
    ok(!$cart->can('custom'));

    my $item = $cart->add({
        sku    => 'SKU123'
    });

    isa_ok($item, 'Handel::Cart::Item');
    is(ref $item, 'Handel::Cart::Item');
    ok(!$item->can('custom'));
};