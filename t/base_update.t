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
        plan tests => 10;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage::DBIC->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [Handel::Test->init_schema(no_populate => 1)->dsn]
    });

    my $schema = $storage->schema_instance;

    $schema->resultset('Carts')->create({
        id => 1,
        shopper => 1,
        name => 'Cart1',
        description => 'My Cart 1'
    });

    my $it = $schema->resultset('Carts')->search({id => 1});

    my $iterator = $storage->iterator_class->new({
        data => $it,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });

    my $cart = Handel::Base->create_instance($iterator->next, $storage);

    is($cart->result->id, 1, 'got result id');
    is($cart->result->shopper, 1, 'got result shopper');
    is($cart->result->name, 'Cart1', 'ot result name');
    is($cart->result->description, 'My Cart 1', 'got result description');

    $cart->result->set_column('name', 'UpdatedName');
    is($cart->result->name, 'UpdatedName', 'got result name');

    my $reit = $schema->resultset('Carts')->search({id => 1});
    my $reiter = $storage->iterator_class->new({
        data => $reit,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });

    my $recart = Handel::Base->create_instance($reiter->first, $storage);
    is($recart->result->name, 'Cart1', 'got result name');

    $cart->update;

    my $it2 = $schema->resultset('Carts')->search({id => 1});
    my $reit2 = $storage->iterator_class->new({
        data => $it2,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });


    my $recart2 = Handel::Base->create_instance($reit2->first, $storage);
    is($recart2->result->name, 'UpdatedName', 'got updated result name');
};
