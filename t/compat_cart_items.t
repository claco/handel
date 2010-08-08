#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 278;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:cart :returnas));
    use_ok('Handel::Exception', ':try');

    local $ENV{'LANGUAGE'} = 'en';

    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    {
        no strict 'refs';
        unshift @{"$subclass\:\:ISA"}, 'Handel::Compat' unless $subclass->isa('Handel::Compat');
        unshift @{"itemclass\:\:ISA"}, 'Handel::Compat' unless $itemclass->isa('Handel::Compat');
        $subclass->storage->currency_class('Handel::Compat::Currency');
        $itemclass->storage->currency_class('Handel::Compat::Currency');
    };


    ## load multiple item Handel::Cart object and get items array on RETURNAS_AUTO
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my @items = $cart->items;
        is(scalar @items, $cart->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        cmp_currency($item1->price, 1.11);
        is($item1->description, 'Line Item SKU 1');
        cmp_currency($item1->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        cmp_currency($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };


        ## get single item as item
        my $single = $cart->items({id => '22222222-2222-2222-2222-222222222222'}, 42);
        isa_ok($single, $itemclass);


        ## in list context, and without iterator
        my @listitems = $cart->items(undef, RETURNAS_ITERATOR);
        is(scalar @listitems, 1);
        isa_ok($listitems[0], 'Handel::Iterator');


        ## thank god this crap went away :-)
        my $list = $cart->items(undef, RETURNAS_LIST);
        is($list, 2);

        my ($c1, $c2) = $cart->items(undef, RETURNAS_LIST);
        isa_ok($c1, $itemclass);
        isa_ok($c2, $itemclass);


        ## While we are here, lets poop out a max quantity exception
        ## There should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 5;
            local $ENV{'HandelMaxQuantityAction'} = 'Exception';

            try {
                $item2->quantity(6);
            } catch Handel::Exception::Constraint with {
                pass;
            } otherwise {
                fail;
            };
        };


        ## While we are here, lets poop out a max quantity adjustment
        ## There should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 2;

            $item2->quantity(6);
            is($item2->quantity, 2);
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
    };


    ## load multiple item Handel::Cart object and get items array on RETURNAS_LIST
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my @items = $cart->items(undef, RETURNAS_LIST);
        is(scalar @items, $cart->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        cmp_currency($item1->price, 1.11);
        is($item1->description, 'Line Item SKU 1');
        cmp_currency($item1->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        cmp_currency($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Cart object and get items Iterator
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $items = $cart->items;
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2);
    };


    ## load multiple item Handel::Cart object and get filter single item
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $item2 = $cart->items({sku => 'SKU2222'});
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        cmp_currency($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Cart object and get filter single item to Iterator
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'SKU2222'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load multiple item Handel::Cart object and get wildcard filter to Iterator
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'SKU%'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2);
    };


    ## load multiple item Handel::Cart object and get filter bogus item to Iterator
    {
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
        cmp_currency($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'notfound'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };

};
