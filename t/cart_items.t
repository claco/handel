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
        plan tests => 491;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:cart));
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


    ## load multiple item Handel::Cart object and get items array
    {
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

        my @items = $cart->items;
        is(scalar @items, $cart->count, 'loaded all items');

        my $item1 = $items[0];
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

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item2->cart, $cart->id, 'cart id is set');
        is($item2->sku, 'SKU2222', 'got sku');
        is($item2->quantity, 2, 'quantity is 2');
        cmp_currency($item2->price+0, 2.22, 'price is 2.22');
        is($item2->description, 'Line Item SKU 2', 'got description');
        cmp_currency($item2->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom', 'got custom field');
        };

        ## While we are here, lets poop out a max quantity exception
        ## There should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 5;
            local $ENV{'HandelMaxQuantityAction'} = 'Exception';

            try {
                local $ENV{'LANGUAGE'} = 'en';
                $item2->quantity(6);

                fail('no exception thrown');
            } catch Handel::Exception::Constraint with {
                pass('caught constraint exception');
                like(shift, qr/failed database constraint/i, 'failed constraint in message');
            } otherwise {
                fail('caught other exception');
            };
        };


        ## While we are here, lets poop out a max quantity adjustment
        ## There should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 2;

            $item2->quantity(6);
            is($item2->quantity, 2, 'quantity is 2');
        };


        ## throw exception when filter isn't a hashref
        {
            try {
                local $ENV{'LANGUAGE'} = 'en';
                $cart->items(['foo']);

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
                $cart->items({}, []);

                fail('no exception thrown');
            } catch Handel::Exception::Argument with {
                pass('Argument exception thrown');
                like(shift, qr/not a hash/i, 'not a hash ref in message');
            } otherwise {
                fail('Other exception thrown');
            };
        };


        ## test out order_by
        my @oitems = $cart->items(undef, {order_by => 'id DESC'});
        is(scalar @oitems, 2, 'has 2 ordered items');
        is($oitems[0]->id, '22222222-2222-2222-2222-222222222222', 'first item is last');
        is($oitems[1]->id, '11111111-1111-1111-1111-111111111111', 'last item is first');
    };


    ## load multiple item Handel::Cart object and get items array
    {
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
        cmp_currency($cart->subtotal+0, 5.55, 'total is 5.55');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom', 'got custom field');
        };

        my @items = $cart->items();
        is(scalar @items, $cart->count, 'loaded same items');

        my $item1 = $items[0];
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

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item2->cart, $cart->id, 'cart id is set');
        is($item2->sku, 'SKU2222', 'got sku');
        is($item2->quantity, 2, 'quantity is 2');
        cmp_currency($item2->price+0, 2.22, 'price is 2.22');
        is($item2->description, 'Line Item SKU 2', 'got description');
        cmp_currency($item2->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom', 'got custom field');
        };
    };


    ## load multiple item Handel::Cart object and get items Iterator
    {
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
        is($items->count, 2, 'has 2 items');
    };


    ## load multiple item Handel::Cart object and get filter single item
    {
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

        my $itemit = $cart->items({sku => 'SKU2222'});
        isa_ok($itemit, 'Handel::Iterator');
        is($itemit, 1, 'has 1 item');

        my $item2 = $itemit->first;
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222', 'got item id');
        is($item2->cart, $cart->id, 'cart id is set');
        is($item2->sku, 'SKU2222', 'got sku');
        is($item2->quantity, 2, 'quantity is 2');
        cmp_currency($item2->price+0, 2.22, 'price is 2.22');
        is($item2->description, 'Line Item SKU 2', 'got description');
        cmp_currency($item2->total+0, 4.44, 'total is 4.44');
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom', 'got custom field');
        };
    };


    ## load multiple item Handel::Cart object and get filter single item to Iterator
    {
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

        my $iterator = $cart->items({sku => 'SKU2222'});
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load multiple item Handel::Cart object and get wildcard filter to Iterator
    ## using SQL::Abstract wildcard syntax
    {
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

        my $iterator = $cart->items({sku => {like=>'SKU%'}});
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2, 'has 2 items');
    };


    ## load multiple item Handel::Cart object and get wildcard filter to Iterator
    ## using old style wildcard syntax
    {
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
        cmp_currency($cart->subtotal+0, 5.55, 'subtotal is 2.22');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom', 'got custom field');
        };

        my $iterator = $cart->items({sku => 'SKU%'});
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2, 'has 2 items');
    };


    ## load multiple item Handel::Cart object and get filter bogus item to Iterator
    {
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

        my $iterator = $cart->items({sku => 'notfound'});
        isa_ok($iterator, 'Handel::Iterator');
    };

};
