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
        plan tests => 110;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
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

    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->delete(id => '1234');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not a hash/i, 'not a hash in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    my $total_items = $subclass->storage->schema_instance->resultset('Items')->count;
    ok($total_items, 'has items in table');


    ## Delete a single cart item contents and validate counts
    {
        my $it = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1, 'loaded 1 cart');

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $related_items = $cart->count;
        is($related_items, 1, 'has 1 item');
        cmp_currency($cart->subtotal+0, 9.99, 'subtotal is 9.99');
        is($cart->delete({sku => 'SKU3333'}), 1, 'deleted sku3333');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'subtotal is 0');

        my $reit = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1, 'loaded 1 cart');

        my $recart = $reit->first;
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0, 'has 0 items');
        is($recart->subtotal+0, 0.00, 'subtotal is 0');

        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items, 'other items still in table');

        $total_items -= $related_items;
    };


    ## Delete multiple cart item contents with wildcard filter and validate
    ## counts using the old style wildcards
    {
        my $it = $subclass->search({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1, 'loaded 1 cart');

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $related_items = $cart->count;
        is($related_items, 2, 'has 2 items');
        cmp_currency($cart->subtotal+0, 45.51, 'subtotal is 45.51');
        ok($cart->delete({sku => 'SKU%'}), 'deleted SKU%');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'subtotal is 0');

        my $reit = $subclass->search({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1, 'loaded 1 cart');

        my $recart = $reit->first;
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0, 'has 0 items');
        is($recart->subtotal+0, 0.00, 'subtotal is 0');

        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items, 'table still has unrelated items');
    };
};
