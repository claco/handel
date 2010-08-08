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
        plan tests => 395;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## load multiple item Handel::Order object and get items array
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my @items = $order->items;
        is(scalar @items, $order->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Order::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->orderid, $order->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        cmp_currency($item1->price+0, 1.11);
        is($item1->description, 'Line Item SKU 1');
        if ($itemclass ne 'Handel::Order::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Order::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->orderid, $order->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price+0, 2.22);
        is($item2->description, 'Line Item SKU 2');
        if ($itemclass ne 'Handel::Order::Item') {
            is($item2->custom, 'custom');
        };


        ## throw exception when options isn't a hashref
        {
            try {
                local $ENV{'LANGUAGE'} = 'en';
                $order->items({}, []);

                fail('no exception thrown');
            } catch Handel::Exception::Argument with {
                pass('Argument exception thrown');
                like(shift, qr/not a hash/i, 'not a hash ref in message');
            } otherwise {
                fail('Other exception thrown');
            };
        };


        ## test out order_by
        my @oitems = $order->items(undef, {order_by => 'id DESC'});
        is(scalar @oitems, 2);
        is($oitems[0]->id, '22222222-2222-2222-2222-222222222222', 'first item is last');
        is($oitems[1]->id, '11111111-1111-1111-1111-111111111111', 'last item is first');


        ## throw exception when filter isn't a hashref
        {
            try {
                local $ENV{'LANGUAGE'} = 'en';
                $order->items(['foo']);

                fail('no exception thrown');
            } catch Handel::Exception::Argument with {
                pass('Argument exception thrown');
                like(shift, qr/not a hash/i, 'not a hash ref in message');
            } otherwise {
                fail('Other exception thrown');
            };
        };
    };


    ## load multiple item Handel::Order object and get items array
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type,ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my @items = $order->items();
        is(scalar @items, $order->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Order::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->orderid, $order->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        cmp_currency($item1->price+0, 1.11);
        is($item1->description, 'Line Item SKU 1');
        if ($itemclass ne 'Handel::Order::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Order::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->orderid, $order->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price+0, 2.22);
        is($item2->description, 'Line Item SKU 2');
        if ($itemclass ne 'Handel::Order::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Order object and get items Iterator
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $items = $order->items;
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2);
    };


    ## load multiple item Handel::Order object and get filter single item
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $itemit = $order->items({sku => 'SKU2222'});
        isa_ok($itemit, 'Handel::Iterator');
        is($itemit, 1);

        my $item2 = $itemit->first;
        isa_ok($item2, 'Handel::Order::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->orderid, $order->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        cmp_currency($item2->price+0, 2.22);
        is($item2->description, 'Line Item SKU 2');
        if ($itemclass ne 'Handel::Order::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Order object and get filter single item to Iterator
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $iterator = $order->items({sku => 'SKU2222'});
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load multiple item Handel::Order object and get wilcard filter to Iterator
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $iterator = $order->items({sku => 'SKU%'});
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2);
    };


    ## load multiple item Handel::Order object and get wilcard filter to Iterator
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $iterator = $order->items({sku => {like => 'SKU%'}});
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2);
    };


    ## load multiple item Handel::Order object and get filter bogus item to Iterator
    {
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        my $iterator = $order->items({sku => 'notfound'});
        isa_ok($iterator, 'Handel::Iterator');
    };

};
