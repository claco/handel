#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 510;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(no_populate => 1, db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->search(id => '1234');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'not a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## throw exception when options isn't a hashref
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->search({id => '1234'}, []);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'not a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## test order_by option
    {
        my @carts = $subclass->search(undef, {order_by => 'id DESC'});
        is(scalar @carts, 3, 'returned 3 carts');
        is($carts[0]->id, '33333333-3333-3333-3333-333333333333', 'last cart is first');
        is($carts[1]->id, '22222222-2222-2222-2222-222222222222', 'middle cart is middle');
        is($carts[2]->id, '11111111-1111-1111-1111-111111111111', 'first cart is last');
    };


    ## load a single cart returning a Handel::Cart object
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1, 'found 1 cart');

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, 'Cart 1', 'got name');
        is($cart->description, 'Test Temp Cart 1', 'got description');
        is($cart->count, 2, 'has two items');
        cmp_currency($cart->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom', 'got custom field');
        };
    };


    ## load a single cart returning a Handel::Cart object from an instance
    {
        my $instance = bless {}, $subclass;
        my $it = $instance->search({
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
    };


    ## load a single cart returning a Handel::Iterator object
    {
        my $iterator = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all carts for the shopper returning a Handel::Iterator object
    {
        my $iterator = $subclass->search({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all carts into an array without a filter
    {
        my @carts = $subclass->search();
        is(scalar @carts, 3, 'loaded 3 carts');

        my $cart1 = $carts[0];
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart1->type, CART_TYPE_TEMP, 'got temp type');
        is($cart1->name, 'Cart 1', 'got name');
        is($cart1->description, 'Test Temp Cart 1', 'got description');
        is($cart1->count, 2, 'has 2 items');
        cmp_currency($cart1->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom', 'got custom field');
        };

        my $cart2 = $carts[1];
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart2->type, CART_TYPE_TEMP, 'got temp type');
        is($cart2->name, 'Cart 2', 'got name');
        is($cart2->description, 'Test Temp Cart 2', 'got description');
        is($cart2->count, 1, 'has 1 item');
        cmp_currency($cart2->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom', 'got custom field');
        };

        my $cart3 = $carts[2];
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($cart3->type, CART_TYPE_SAVED, 'got saved type');
        is($cart3->name, 'Cart 3', 'got name');
        is($cart3->description, 'Saved Cart 1', 'got description');
        is($cart3->count, 2, 'has 2 items');
        cmp_currency($cart3->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom', 'got custom field');
        };
    };


    ## load all carts into an array without a filter
    {
        my @carts = $subclass->search();
        is(scalar @carts, 3, 'loaded 3 carts');

        my $cart1 = $carts[0];
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart1->type, CART_TYPE_TEMP, 'got temp type');
        is($cart1->name, 'Cart 1', 'got name');
        is($cart1->description, 'Test Temp Cart 1', 'got description');
        is($cart1->count, 2, 'has 2 items');
        cmp_currency($cart1->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom', 'got custom field');
        };

        my $cart2 = $carts[1];
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart2->type, CART_TYPE_TEMP, 'got temp type');
        is($cart2->name, 'Cart 2', 'got name');
        is($cart2->description, 'Test Temp Cart 2', 'got description');
        is($cart2->count, 1, 'has 1 item');
        cmp_currency($cart2->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom', 'got custom field');
        };

        my $cart3 = $carts[2];
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($cart3->type, CART_TYPE_SAVED, 'got saved type');
        is($cart3->name, 'Cart 3', 'got name');
        is($cart3->description, 'Saved Cart 1', 'got description');
        is($cart3->count, 2, 'has 2 items');
        cmp_currency($cart3->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom', 'got custom field');
        };
    };


    ## load all carts into an array with a filter
    {
        my @carts = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222',
            name => 'Cart 2'
        });
        is(scalar @carts, 1, 'loaded 1 cart');

        my $cart = $carts[0];
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, 'Cart 2', 'got name');
        is($cart->description, 'Test Temp Cart 2', 'got description');
        is($cart->count, 1, 'has 1 item');
        cmp_currency($cart->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom', 'got custom field');
        };
    };


    ## load all carts into an array with a wildcard filter using SQL::Abstract
    ## wildcard syntax
    {
        my @carts = $subclass->search({
            name => {like => 'Cart %'}
        });
        is(scalar @carts, 3, 'loaded 3 carts');

        my $cart1 = $carts[0];
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart1->type, CART_TYPE_TEMP, 'got temp type');
        is($cart1->name, 'Cart 1', 'got name');
        is($cart1->description, 'Test Temp Cart 1', 'got description');
        is($cart1->count, 2, 'has 2 items');
        cmp_currency($cart1->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom', 'got custom field');
        };

        my $cart2 = $carts[1];
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart2->type, CART_TYPE_TEMP, 'got temp type');
        is($cart2->name, 'Cart 2', 'got name');
        is($cart2->description, 'Test Temp Cart 2', 'got description');
        is($cart2->count, 1, 'has 1 item');
        cmp_currency($cart2->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom', 'got custom field');
        };

        my $cart3 = $carts[2];
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($cart3->type, CART_TYPE_SAVED, 'got saved type');
        is($cart3->name, 'Cart 3', 'got name');
        is($cart3->description, 'Saved Cart 1', 'got description');
        is($cart3->count, 2, 'has 2 items');
        cmp_currency($cart3->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom', 'got custom field');
        };
    };


    ## load all carts into an array with a wildcard filter using old
    ## wildcard syntax
    {
        my @carts = $subclass->search({
            name => 'Cart %'
        });
        is(scalar @carts, 3, 'loaded 3 carts');

        my $cart1 = $carts[0];
        isa_ok($cart1, 'Handel::Cart');
        isa_ok($cart1, $subclass);
        is($cart1->id, '11111111-1111-1111-1111-111111111111', 'got cart id');
        is($cart1->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart1->type, CART_TYPE_TEMP, 'got temp type');
        is($cart1->name, 'Cart 1', 'got name');
        is($cart1->description, 'Test Temp Cart 1', 'got description');
        is($cart1->count, 2, 'has 2 items');
        cmp_currency($cart1->subtotal+0, 5.55, 'subtotal is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart1->custom, 'custom', 'got custom field');
        };

        my $cart2 = $carts[1];
        isa_ok($cart2, 'Handel::Cart');
        isa_ok($cart2, $subclass);
        is($cart2->id, '22222222-2222-2222-2222-222222222222', 'got cart id');
        is($cart2->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart2->type, CART_TYPE_TEMP, 'got temp type');
        is($cart2->name, 'Cart 2', 'got name');
        is($cart2->description, 'Test Temp Cart 2', 'got description');
        is($cart2->count, 1, 'has 1 item');
        cmp_currency($cart2->subtotal+0, 9.99, 'subtotal is 9.99');
        if ($subclass ne 'Handel::Cart') {
            is($cart2->custom, 'custom', 'got custom field');
        };

        my $cart3 = $carts[2];
        isa_ok($cart3, 'Handel::Cart');
        isa_ok($cart3, $subclass);
        is($cart3->id, '33333333-3333-3333-3333-333333333333', 'got cart id');
        is($cart3->shopper, '33333333-3333-3333-3333-333333333333', 'got shopper id');
        is($cart3->type, CART_TYPE_SAVED, 'got saved type');
        is($cart3->name, 'Cart 3', 'got name');
        is($cart3->description, 'Saved Cart 1', 'got description');
        is($cart3->count, 2, 'has 2 items');
        cmp_currency($cart3->subtotal+0, 45.51, 'subtotal is 45.51');
        if ($subclass ne 'Handel::Cart') {
            is($cart3->custom, 'custom', 'got custom field');
        };
    };


    ## load returns 0
    {
        my $cart = $subclass->search({
            id => 'notfound'
        });
        is($cart, 0, 'loaded no carts');
    };

};


## pass in storage instead
{
    my $storage = Handel::Cart->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    $altschema->resultset('Carts')->create({
        id      => '88888888-8888-8888-8888-888888888888',
        shopper => '88888888-8888-8888-8888-888888888888',
        type    => CART_TYPE_SAVED,
        name    => 'My Alt Cart',
        description => 'My Alt Cart Description'
    });

    my $cart = Handel::Cart->search({
        name => 'My Alt Cart'
    }, {
        storage => $storage
    })->first;
    isa_ok($cart, 'Handel::Cart');
    is($cart->shopper, '88888888-8888-8888-8888-888888888888', 'got shopper id');
    is($cart->type, CART_TYPE_SAVED, 'got saved type');
    is($cart->name, 'My Alt Cart', 'got name');
    is($cart->description, 'My Alt Cart Description', 'got description');
    is($cart->count, 0, 'has no items');
    is($cart->subtotal+0, 0, 'subtotal is 0');
    is(refaddr $cart->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 1, 'cart found in alt storage');
    is($schema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 0, 'alt cart not in class storage');
};
