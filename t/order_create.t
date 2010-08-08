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
        plan tests => 656;
    };

    use_ok('Handel::Constants', qw(:order :checkout));
    use_ok('Handel::Cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};


eval 'use Test::MockObject 1.07';
if (!$@) {
    my $mock = Test::MockObject->new();

    $mock->fake_module('Handel::Checkout');
    $mock->fake_new('Handel::Checkout');
    $mock->set_series('process',
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR, #&run1
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR, #&run2
        CHECKOUT_STATUS_OK, CHECKOUT_STATUS_ERROR  #&run3
    );
    $mock->mock(order => sub {
        my ($self, $order) = @_;

        $self->{'order'} = $order if $order;

        return $self->{'order'};
    });
};
use_ok('Handel::Order');
use_ok('Handel::Subclassing::Order');
use_ok('Handel::Subclassing::OrderOnly');
use_ok('Handel::Subclassing::Cart');


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(no_populate => 1, db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->clear_schema($schema);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $order = $subclass->create(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## constraint_uuid is no longer used for interchangable schemas
    {
        try {
            my $order = $subclass->create({cart => '1234'});

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart key is not a hashref
    {
        try {
            my $order = $subclass->create({cart => []});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where cart is
    {
        try {
            my $fake = bless {}, 'MyObject::Foo';
            my $order = $subclass->create({cart => $fake});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Order when no Handel::Cart matches the search criteria
    {
        try {
            my $order = $subclass->create({cart => {id => '1111'}});

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Order when Handel::Cart is empty
    {
        try {
            my $cart = Handel::Cart->create({
                id      => '00000000-0000-0000-0000-00000000000' . $dbsuffix,
                shopper => '00000000-0000-0000-0000-000000000000'
            });
            my $order = $subclass->create({cart => $cart});

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
        warn shift->text;
            fail;
        };
    };


    ## test for Handel::Exception::Order when Handel::Cart subclass is empty
    {
        try {
            my $cart = Handel::Subclassing::Cart->search({
                id => '00000000-0000-0000-0000-00000000000' . $dbsuffix
            })->first;
            my $order = $subclass->create({cart => $cart});

            fail;
        } catch Handel::Exception::Order with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Constraint during order new for bogus shopper
    {
        try {
            my $order = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => 'crap'
            });

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };

SKIP: {
    if (DBD::SQLite->VERSION eq '1.13' || DBD::SQLite->VERSION eq '1.14') {
        skip 'DBD::SQLite 1.13 wonky on some platforms', 2;
    };

    ## test for raw db key violation
    {
        my $order = $subclass->create({
            id      => '11111111-1111-1111-1111-11111111111' . $dbsuffix,
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($order, 'Handel::Order');

        try {
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-11111111111' . $dbsuffix,
                shopper => '11111111-1111-1111-1111-111111111111'
            }, 1);

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };
};


    ## add a new temp order and test auto id creation
    {
        my $order = $subclass->create({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        ok(constraint_uuid($order->id));
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 0);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, undef);
        };
    };


    ## add a new temp order and supply a manual id
    {
        my $order = $subclass->create({
            id      => '77777777-7777-7777-7777-777777777777',
            shopper => '77777777-7777-7777-7777-777777777777'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        ok(constraint_uuid($order->id));
        is($order->id, '77777777-7777-7777-7777-777777777777');
        is($order->shopper, '77777777-7777-7777-7777-777777777777');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 0);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, undef);
        };

        is($order->subtotal->stringify, '0.00 USD');
        is($order->subtotal->stringify('FMT_NAME'), '0.00 US Dollar');
        
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($order->subtotal->stringify, '0.00 CAD');
            is($order->subtotal->stringify('FMT_NAME'), '0.00 Canadian Dollar');
        };
    };


    ## add a new temp order and test all fields from hash
    {
        my $data = {
            id      => '88888888-8888-8888-8888-888888888888',
            shopper => '88888888-8888-8888-8888-888888888888',
            type    => ORDER_TYPE_TEMP,
            number  => 'O20050723125366',
            created => '2005-07-23 12:53:55',
            updated => DateTime->new(
                year   => 2005,
                month  => 8,
                day    => 23,
                hour   => 12,
                minute => 53,
                second => 55,
                time_zone => 'UTC'
            ),
            comments => 'Rush Order Please',
            shipmethod => 'UPS Ground',
            shipping   => 1.23,
            handling   => 4.56,
            tax        => 7.89,
            subtotal   => 10.11,
            total      => Handel::Currency->new(12.13),
            billtofirstname    => 'Christopher',
            billtolastname     => 'Laco',
            billtoaddress1     => 'BillToAddress1',
            billtoaddress2     => 'BillToAddress2',
            billtoaddress3     => 'BillToAddress3',
            billtocity         => 'BillToCity',
            billtostate        => 'BillToState',
            billtozip          => 'BillToZip',
            billtocountry      => 'BillToCountry',
            billtodayphone     => '1-111-111-1111',
            billtonightphone   => '2-222-222-2222',
            billtofax          => '3-333-333-3333',
            billtoemail        => 'mendlefarg@gmail.com',
            shiptosameasbillto => 1,
            shiptoaddress1     => 'ShipToAddress1',
            shiptoaddress2     => 'ShipToAddress2',
            shiptoaddress3     => 'ShipToAddress3',
            shiptocity         => 'ShipToCity',
            shiptostate        => 'ShipToState',
            shiptozip          => 'ShipToZip',
            shiptocountry      => 'ShipToCountry',
            shiptodayphone     => '4-444-444-4444',
            shiptonightphone   => '5-555-555-5555',
            shiptofax          => '6-666-666-6666',
            shiptoemail        => 'chrislaco@hotmail.com',
        };
        if ($subclass ne 'Handel::Order') {
            $data->{'custom'} = 'custom';
        };
        my $order = $subclass->create($data);
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        ok(constraint_uuid($order->id));
        is($order->id, '88888888-8888-8888-8888-888888888888');
        is($order->shopper, '88888888-8888-8888-8888-888888888888');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 0);
        is($order->number, 'O20050723125366');
        is($order->created . '', '2005-07-23T12:53:55');
        is($order->updated . '', '2005-08-23T12:53:55');
        is($order->comments, 'Rush Order Please');
        is($order->shipmethod, 'UPS Ground');
        is($order->shipping+0, 1.23);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };


        is($order->shipping->stringify, '1.23 USD');
        is($order->shipping->stringify('FMT_NAME'), '1.23 US Dollar');
        is($order->handling+0, 4.56);
        is($order->handling->stringify, '4.56 USD');
        is($order->handling->stringify('FMT_NAME'), '4.56 US Dollar');
        is($order->tax+0, 7.89);
        is($order->tax->stringify, '7.89 USD');
        is($order->tax->stringify('FMT_NAME'), '7.89 US Dollar');
        is($order->subtotal+0, 10.11);
        is($order->subtotal->stringify, '10.11 USD');
        is($order->subtotal->stringify('FMT_NAME'), '10.11 US Dollar');
        is($order->total+0, 12.13);
        is($order->total->stringify, '12.13 USD');
        is($order->total->stringify('FMT_NAME'), '12.13 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($order->shipping->stringify, '1.23 CAD');
            is($order->shipping->stringify('FMT_NAME'), '1.23 Canadian Dollar');
            is($order->handling->stringify, '4.56 CAD');
            is($order->handling->stringify('FMT_NAME'), '4.56 Canadian Dollar');
            is($order->tax->stringify, '7.89 CAD');
            is($order->tax->stringify('FMT_NAME'), '7.89 Canadian Dollar');
            is($order->subtotal->stringify, '10.11 CAD');
            is($order->subtotal->stringify('FMT_NAME'), '10.11 Canadian Dollar');
            is($order->total->stringify, '12.13 CAD');
            is($order->total->stringify('FMT_NAME'), '12.13 Canadian Dollar');
        };

        is($order->billtofirstname, 'Christopher');
        is($order->billtolastname, 'Laco');
        is($order->billtoaddress1, 'BillToAddress1');
        is($order->billtoaddress2, 'BillToAddress2');
        is($order->billtoaddress3, 'BillToAddress3');
        is($order->billtocity, 'BillToCity');
        is($order->billtostate, 'BillToState');
        is($order->billtozip, 'BillToZip');
        is($order->billtocountry, 'BillToCountry');
        is($order->billtodayphone, '1-111-111-1111');
        is($order->billtonightphone, '2-222-222-2222');
        is($order->billtofax, '3-333-333-3333');
        is($order->billtoemail, 'mendlefarg@gmail.com');
        is($order->shiptosameasbillto, 1);
        is($order->shiptoaddress1, 'ShipToAddress1');
        is($order->shiptoaddress2, 'ShipToAddress2');
        is($order->shiptoaddress3, 'ShipToAddress3');
        is($order->shiptocity, 'ShipToCity');
        is($order->shiptostate, 'ShipToState');
        is($order->shiptozip, 'ShipToZip');
        is($order->shiptocountry, 'ShipToCountry');
        is($order->shiptodayphone, '4-444-444-4444');
        is($order->shiptonightphone, '5-555-555-5555');
        is($order->shiptofax, '6-666-666-6666');
        is($order->shiptoemail, 'chrislaco@hotmail.com');
    };


    {
        ## create and order from a Handel::Cart object and test currency
        my $cart = Handel::Cart->create({
            id=>'66BFFD29-8FAD-4200-A22F-E0D80979ADB'.$dbsuffix,
            shopper=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF',
            name=>'My First Cart'
        });
        my $item = $cart->add({
            id => '5A8E0C3D-92C3-49b1-A988-585C792B752'.$dbsuffix,
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item',
        });

        my $order = $subclass->create({
            cart => $cart,
            shopper=>'66BFFD29-8FAD-4200-A22F-E0D80979ADBF'
        });

        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, undef);
        };

        is($order->subtotal->stringify, '2.22 USD');
        is($order->subtotal->stringify('FMT_NAME'), '2.22 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($order->subtotal->stringify, '2.22 CAD');
            is($order->subtotal->stringify('FMT_NAME'), '2.22 Canadian Dollar');
        };

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
        if ($itemclass ne 'Handel::Order::Item') {
            is($orderitem->custom, undef);
        };

        is($orderitem->price->stringify, '1.11 USD');
        is($orderitem->price->stringify('FMT_NAME'), '1.11 US Dollar');
        is($orderitem->total->stringify, '2.22 USD');
        is($orderitem->total->stringify('FMT_NAME'), '2.22 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($orderitem->price->stringify, '1.11 CAD');
            is($orderitem->price->stringify('FMT_NAME'), '1.11 Canadian Dollar');
            is($orderitem->total->stringify, '2.22 CAD');
            is($orderitem->total->stringify('FMT_NAME'), '2.22 Canadian Dollar');
        };
    };



    {
        ## create and order from a Handel::Cart subclass object and test currency
        my $cart = Handel::Subclassing::Cart->create({
            id=>'76BFFD29-8FAD-4200-A22F-E0D80979ADB'.$dbsuffix,
            shopper=>'76BFFD29-8FAD-4200-A22F-E0D80979ADBF',
            name=>'My First Cart',
            custom=>'custom'}
        );
        my $item = $cart->add({
            id => '6A8E0C3D-92C3-49b1-A988-585C792B752'.$dbsuffix,
            sku => 'sku1',
            quantity => 2,
            price => 1.11,
            description => 'My First Item'
        });

        my $order = $subclass->create({
            cart => $cart,
            shopper=>'76BFFD29-8FAD-4200-A22F-E0D80979ADBF'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, undef);
        };


        is($order->subtotal->stringify, '2.22 USD');
        is($order->subtotal->stringify('FMT_NAME'), '2.22 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($order->subtotal->stringify, '2.22 CAD');
            is($order->subtotal->stringify('FMT_NAME'), '2.22 Canadian Dollar');
        };

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
        if ($itemclass ne 'Handel::Order::Item') {
            is($orderitem->custom, undef);
        };

        is($orderitem->price->stringify, '1.11 USD');
        is($orderitem->price->stringify('FMT_NAME'), '1.11 US Dollar');
        is($orderitem->total->stringify, '2.22 USD');
        is($orderitem->total->stringify('FMT_NAME'), '2.22 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($orderitem->price->stringify, '1.11 CAD');
            is($orderitem->price->stringify('FMT_NAME'), '1.11 Canadian Dollar');
            is($orderitem->total->stringify, '2.22 CAD');
            is($orderitem->total->stringify('FMT_NAME'), '2.22 Canadian Dollar');
        };
    };


    {
        ## create and order from a search hash
        my $cart = Handel::Cart->create({
            id=>'F00F8DE0-A39C-41e4-A906-D43DF55D93D'.$dbsuffix,
            shopper=>'F00F8DE0-A39C-41e4-A906-D43DF55D93D8',
            name=>'My Other Second Cart'
        });
        my $item = $cart->add({
            id => 'B1247A21-E121-470e-AA97-245B7BD7CD1'.$dbsuffix,
            sku => 'sku2',
            quantity => 3,
            price => 2.22,
            description => 'My Second Item'
        });

        my $order = $subclass->create({
            cart => {id => 'F00F8DE0-A39C-41e4-A906-D43DF55D93D'.$dbsuffix},
            shopper=>'F00F8DE0-A39C-41e4-A906-D43DF55D93D8'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    {
        ## create and order from a cart id
        my $cart = Handel::Cart->create({
            id=>'99BE4783-2A16-4172-A5A8-415A7D984BC'.$dbsuffix,
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA',
            name=>'My Other Third Cart'
        });
        my $item = $cart->add({
            id => '699E1E68-0DCE-43d5-A747-F380769DDCF'.$dbsuffix,
            sku => 'sku3',
            quantity => 2,
            price => 1.23,
            description => 'My Third Item'
        });

        my $order = $subclass->create({
            cart => '99BE4783-2A16-4172-A5A8-415A7D984BC'.$dbsuffix,
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    {
        ## create and order from a cart id and inherit shopper id
        my $cart = Handel::Cart->create({
            id=>'29BE4783-2A16-4172-A5A8-415A7D984BC'.$dbsuffix,
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA',
            name=>'My Other Third Cart'
        });
        my $item = $cart->add({
            id => '299E1E68-0DCE-43d5-A747-F380769DDCF'.$dbsuffix,
            sku => 'sku3',
            quantity => 2,
            price => 1.23,
            description => 'My Third Item'
        });

        my $order = $subclass->create({
            cart => '29BE4783-2A16-4172-A5A8-415A7D984BC'.$dbsuffix
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);
        is($order->shopper, $cart->shopper, 'shopper id was copied');

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    {
        ## create and order from a cart object without a shopper accessor
        my $cart = Handel::Cart->create({
            id=>'19BE4783-2A16-4172-A5A8-415A7D984BC'.$dbsuffix,
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA',
            name=>'My Other Third Cart'
        });
        my $item = $cart->add({
            id => '199E1E68-0DCE-43d5-A747-F380769DDCF'.$dbsuffix,
            sku => 'sku3',
            quantity => 2,
            price => 1.23,
            description => 'My Third Item'
        });

        local *Handel::Cart::can = sub {};
        my $order = $subclass->create({
            cart => $cart,
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, $cart->count);
        is($order->subtotal, $cart->subtotal);

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, $item->sku);
        is($orderitem->quantity, $item->quantity);
        is($orderitem->price, $item->price);
        is($orderitem->description, $item->description);
        is($orderitem->total, $item->total);
        is($orderitem->orderid, $order->id);
    };


    ## check that when multiple carts are found that we only load the first one
    {
        my $order = $subclass->create({
            cart => {name => '%Other%'},
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->count, 1);
        cmp_currency($order->subtotal+0, 6.66);

        my $orderitem = $order->items->first;
        isa_ok($orderitem, 'Handel::Order::Item');
        isa_ok($orderitem, $itemclass);
        is($orderitem->sku, 'sku2');
        is($orderitem->quantity, 3);
        cmp_currency($orderitem->price+0, 2.22);
        is($orderitem->description, 'My Second Item');
        cmp_currency($orderitem->total+0, 6.66);
        is($orderitem->orderid, $order->id);
    };


    ## check defaults for created/updated
    {
        my $order = $subclass->create({
            shopper=>'99BE4783-2A16-4172-A5A8-415A7D984BCA'
        });
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        isa_ok($order->created, 'DateTime');
        isa_ok($order->updated, 'DateTime');
    };
    

    SKIP: {
        eval 'use Test::MockObject 1.07';
        skip 'Test::MockObject 1.07 not installed', 7 if $@;

        ## add a new order and test process::OK (in mock series)
        {
            my $order = $subclass->create({
                shopper => '11111111-1111-1111-1111-111111111111'
            }, {process => 1});
            isa_ok($order, 'Handel::Order');
            isa_ok($order, $subclass);
            ok(constraint_uuid($order->id));
            is($order->shopper, '11111111-1111-1111-1111-111111111111');
            is($order->type, ORDER_TYPE_TEMP);
            is($order->count, 0);
        };


        ## add a new order and test process::ERROR (in mock series)
        {
            my $order = $subclass->create({
                shopper => '11111111-1111-1111-1111-111111111111'
            }, {process => 1});
            is($order, undef);
        };
    };

};


## pass in storage instead
{
    my $storage = Handel::Order->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $order = Handel::Order->create({
        shopper => '88888888-8888-8888-8888-888888888888',
        type    => ORDER_TYPE_SAVED
    }, {
        storage => $storage
    });
    isa_ok($order, 'Handel::Order');
    ok(constraint_uuid($order->id));
    is($order->shopper, '88888888-8888-8888-8888-888888888888');
    is($order->type, ORDER_TYPE_SAVED);
    is($order->count, 0);
    is($order->subtotal+0, 0);
    is(refaddr $order->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('Orders')->search({id => $order->id})->count, 1, 'order found in alt storage');
    is($schema->resultset('Orders')->search({id => $order->id})->count, 0, 'alt order not in class storage');
};
