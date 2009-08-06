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
        plan tests => 86;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


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


    my $total_orders = $subclass->storage->schema_instance->resultset('Orders')->count;
    ok($total_orders);

    my $total_items = $subclass->storage->schema_instance->resultset('Items')->count;
    ok($total_items);


    ## Destroy a single order via instance
    {
        my $it = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $related_items = $order->count;
        is($related_items, 1);
        is($order->subtotal+0, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        $order->destroy;

        my $reit = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 0);

        my $reorder = $reit->first;
        is($reorder, undef);

        my $remaining_orders = $subclass->storage->schema_instance->resultset('Orders')->count;
        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;

        is($remaining_orders, $total_orders - 1);
        is($remaining_items, $total_items - $related_items);

        $total_orders--;
        $total_items -= $related_items;
    };


    ## Destroy multiple orders with wildcard filter
    {
        my $orders = $subclass->search({id => '11111%'});
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 1);

        my $related_items = $orders->first->items->count;
        ok($related_items);

        $subclass->destroy({
            id => '111%'
        });

        $orders = $subclass->search({id => '11111%'});
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 0);

        my $remaining_orders = $subclass->storage->schema_instance->resultset('Orders')->count;
        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;

        is($remaining_orders, $total_orders - 1);
        is($remaining_items, $total_items - $related_items);
    };


    ## Destroy orders on an instance
    {
        my $instance = bless {}, $subclass;
        my $orders = $subclass->search;
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 1, 'loaded 1 order');

        $instance->destroy({
            id => {like => '%'}
        });

        $orders = $subclass->search;
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 0, 'no orders loaded');
    };
};


## pass in storage instead
{
    my $storage = Handel::Order->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    is($altschema->resultset('Orders')->search({id => '11111111-1111-1111-1111-111111111111'})->count, 1, 'order found in alt storage');
    Handel::Order->destroy({
        id => '11111111-1111-1111-1111-111111111111'
    }, {
        storage => $storage
    });
    is($altschema->resultset('Orders')->search({id => '11111111-1111-1111-1111-111111111111'})->count, 0, 'order removed from alt storage');
};


## don't unset self if no result is returned
{
    my $storage = Handel::Order->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $order = Handel::Order->search({id => '22222222-2222-2222-2222-222222222222'}, {storage => $storage})->first;
    ok($order);

    no warnings 'redefine';
    local *Handel::Storage::DBIC::Result::delete = sub {};
    $order->destroy;
    ok($order);
};
