#!perl -wT
# $Id: /local/CPAN/Handel/trunk/t/cart_create.t 1988 2007-10-21T21:05:56.869869Z claco  $
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
        plan tests => 187;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
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
            my $cart = $subclass->create(sku => 'SKU1234');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not a hash/i, 'not a hash in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    ## test for Handel::Exception::Constraint during cart new for bogus shopper
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => 'crap'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/failed database constraint/i, 'failed constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    ## test for Handel::Exception::Constraint during cart new for empty shopper
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/failed database constraint/i, 'failed constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    ## test for Handel::Exception::Constraint during cart new when no name is
    ## specified and cart type has been set to CART_TYPE_SAVED
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => '33333333-3333-3333-3333-333333333333',
                type    => CART_TYPE_SAVED
            });

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/failed database constraint/i, 'failed constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    ## just for giggles, let's pass it in a different way
    {
        my %data = (id      => '11111111-1111-1111-1111-111111111111',
                    shopper => '33333333-3333-3333-3333-333333333333',
                    type    => CART_TYPE_SAVED
        );

        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->create(\%data);

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/failed database constraint/i, 'failed constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };


SKIP: {
    if (DBD::SQLite->VERSION eq '1.13' || DBD::SQLite->VERSION eq '1.14') {
        skip 'DBD::SQLite 1.13 wonky on some platforms', 2;
    };

    ## test for raw db key violation
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => '11111111-1111-1111-1111-111111111111'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/value already exists/i, 'value exists in message');
        } otherwise {
            fail('caught other exception');
        };
    };
};


    ## add a new temp cart and test auto id creation
    {
        my $cart = $subclass->create({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id), 'id is uuid');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111', 'got shopper id');
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, undef, 'name is undef');
        is($cart->description, undef, 'description is undef');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'has 0 subtotal');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef, 'custom is undef');
        };


        is($cart->subtotal->stringify, '0.00 USD', 'subtotal formats 0');
        is($cart->subtotal->stringify('FMT_NAME'), '0.00 US Dollar', 'subtotal formats 0');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($cart->subtotal->stringify, '0.00 CAD', 'subtotal formats 0');
            is($cart->subtotal->stringify('FMT_NAME'), '0.00 Canadian Dollar', 'subtotal formats 0');
        };
    };


    ## add a new temp cart and supply a manual id
    {
        my $cart = $subclass->create({
            id      => '77777777-7777-7777-7777-777777777777',
            shopper => '77777777-7777-7777-7777-777777777777'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id), 'id is uuid');
        is($cart->id, '77777777-7777-7777-7777-777777777777', 'got cart id');
        is($cart->shopper, '77777777-7777-7777-7777-777777777777', 'got shopper id');
        is($cart->type, CART_TYPE_TEMP, 'got temp type');
        is($cart->name, undef, 'name is undef');
        is($cart->description, undef, 'description is undef');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'subtotal is 0');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef, 'custom is unset');
        };
    };


    ## add a new saved cart and test auto id creation
    {
        my $cart = $subclass->create({
            shopper => '88888888-8888-8888-8888-888888888888',
            type    => CART_TYPE_SAVED,
            name    => 'My Cart',
            description => 'My Cart Description'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id), 'id is uuid');
        is($cart->shopper, '88888888-8888-8888-8888-888888888888', 'got shopper id');
        is($cart->type, CART_TYPE_SAVED, 'got saved type');
        is($cart->name, 'My Cart', 'got name');
        is($cart->description, 'My Cart Description', 'got description');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'subtotal is 0');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef, 'custom is undef');
        };
    };


    ## add a new saved cart and supply a manual id
    {
        my $cart = $subclass->create({
            id      => '99999999-9999-9999-9999-999999999999',
            shopper => '99999999-9999-9999-9999-999999999999',
            type    => CART_TYPE_SAVED,
            name    => 'My Cart',
            description => 'My Cart Description'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id), 'id is uuid');
        is($cart->id, '99999999-9999-9999-9999-999999999999', 'got cart id');
        is($cart->shopper, '99999999-9999-9999-9999-999999999999', 'got shopper id');
        is($cart->type, CART_TYPE_SAVED, 'got temp type');
        is($cart->name, 'My Cart', 'got name');
        is($cart->description, 'My Cart Description', 'got description');
        is($cart->count, 0, 'has 0 items');
        is($cart->subtotal+0, 0, 'subtotal is 0');
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef, 'custom is undef');
        };
    };
};


## pass in storage instead
{
    my $storage = Handel::Cart->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $cart = Handel::Cart->create({
        shopper => '88888888-8888-8888-8888-888888888888',
        type    => CART_TYPE_SAVED,
        name    => 'My Alt Cart',
        description => 'My Alt Cart Description'
    }, {
        storage => $storage
    });
    isa_ok($cart, 'Handel::Cart');
    ok(constraint_uuid($cart->id), 'id is uuid');
    is($cart->shopper, '88888888-8888-8888-8888-888888888888', 'got shopper id');
    is($cart->type, CART_TYPE_SAVED, 'got saved type');
    is($cart->name, 'My Alt Cart', 'got name');
    is($cart->description, 'My Alt Cart Description', 'got description');
    is($cart->count, 0, 'has 0 items');
    is($cart->subtotal+0, 0, 'subtotal is 0');
    is(refaddr $cart->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 1, 'cart found in alt storage');
    is($schema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 0, 'alt cart not in class storage');
};
