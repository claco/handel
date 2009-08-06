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
        plan tests => 35;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $default_values = {
    name        => 'My Default Name',
    description => sub {'My Default Description'}
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    default_values  => $default_values,
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->default_values, $default_values, 'default values were set');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::DefaultValues'), 'DefaultValues component is loaded');

    is_deeply($class->default_values, $default_values, 'default values were set');

    ## check insert
    my $cart = $schema->resultset('Carts')->create({id => 1, shopper => 1});
    is($cart->name, 'My Default Name', 'got cart name');
    is($cart->description, 'My Default Description', 'got cart description');

    ## check update
    $class->default_values->{'name'} = 'My Updated Default';
    $cart->name(undef);
    $cart->update;
    is($cart->name, 'My Updated Default', 'updated cart name');

    ## check update with no accessor in column_info
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"$class\:\:column_info"} = sub {return {'accessor' => 'name'}};

        $class->default_values->{'name'} = 'My Updated Default2';
        $cart->name(undef);
        $cart->update;
        is($cart->name, 'My Updated Default2', 'updated cart name');    
    };

    ## check non-hashref
    $class->default_values([]);
    $cart->name(undef);
    $cart->update;
    is($cart->name, undef, 'unset cart name');

    ## check for no values set
    $cart->name('nothing');
    $cart->update;
    is($cart->name, 'nothing', 'updated cart name');
    $class->default_values(undef);
    $cart->name(undef);
    $cart->update;
    is($cart->name, undef, 'unset cart name');

    ## check for non-code ref in hash
    $cart->name('nothing');
    $cart->update;
    is($cart->name, 'nothing', 'set cart name');
    $class->default_values({name => ['foo']});
    $cart->name(undef);
    $cart->update;
    is($cart->name, undef, 'updated cart name');

    ## throw exception when setting a default_values with open schema_instance
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->default_values({
                field => 'foo'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/existing schema instance/i, 'existing schema instance in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    ## throw exception when setting a bogus defaults class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->default_values_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/default_values_class.*could not be loaded/i, 'default_calues_class could not be loaded in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    ## reset it all, and try a custom default values class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef, 'unset schema instance');

    $storage->default_values_class('Handel::TestComponents::DefaultValues');
    is($storage->default_values_class, 'Handel::TestComponents::DefaultValues', 'set default values class');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::DefaultValues'), 'DefaultValues component is loaded');
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::DefaultValues'), 'DefaultValues component is not loaded in original');
};


## do the item_storage default_values too
{
    my $default_values = {
        sku => 'MySKU',
        price => sub {3.21}
    };

    $storage->schema_instance(undef);
    my $item_storage = Handel::Storage::DBIC->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Items',
        default_values  => $default_values
    });
    $storage->item_storage($item_storage);

    is_deeply($storage->item_storage->default_values, $default_values, 'loaded default values');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Items');
    ok($class->isa('Handel::Components::DefaultValues'), 'DefaultValues component is loaded');

    is_deeply($class->default_values, $default_values, 'default values are set');

    ## check insert
    my $item = $schema->resultset('Items')->create({id => 1, cart => 1});
    is($item->sku, 'MySKU', 'got default sku');
    is($item->price, 3.21, 'got default price');

    ## check update
    $class->default_values->{'sku'} = 'MyUpdatedSKU';
    $item->sku(undef);
    $item->update;
    is($item->sku, 'MyUpdatedSKU', 'got updated sku');

    ## check update with no accessor in column_info
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"$class\:\:column_info"} = sub {return {'accessor' => 'sku'}};

        $class->default_values->{'sku'} = 'MyUpdatedSKU2';
        $item->sku(undef);
        $item->update;
        is($item->sku, 'MyUpdatedSKU2', 'got updated sku');    
    };


    ## item_storage without default_values
    $storage->schema_instance(undef);
    $item_storage->schema_instance(undef);
    $item_storage->default_values(undef);
    
    $schema = $storage->schema_instance;

    $class = $schema->class('Items');
    ok(!$class->isa('Handel::Components::DefaultValues'), 'DefaultValues component was not loaded');
    is($storage->item_storage->default_values, undef, 'default values still undef');
};
