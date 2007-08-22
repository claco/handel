#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    };
    eval 'require FormValidator::Simple';
    if ($@) {
        plan skip_all => 'FormValidator::Simple not installed';
    } else {
        plan tests => 38;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $validation = [
    name => ['NOT_BLANK'],
    description => ['NOT_BLANK', ['LENGTH', 2, 4]]
];

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    validation_profile => $validation,
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->validation_profile, $validation, 'validate was set');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::Validation'), 'Validation component is loaded');

    is_deeply($class->validation_profile, $validation, 'validation profile is loaded');


    ## throw exception when validation fails
    my $cart;
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $cart = $schema->resultset('Carts')->create({
                id => 1,
                name => 'test'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Validation with {
            my $e = shift;
            pass('caught validation exception');
            isa_ok($e->results, 'FormValidator::Simple::Results');
            like($e, qr/failed validation/i, 'validation failed in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    is($cart, undef, 'cart is still undefined');


    ## throw exception when setting a validation with open schema_instance
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->validation_profile([
                field => {'do_field' => sub{}}
            ]);

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/existing schema/i, 'existing schema in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception when setting a bogus validation class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->validation_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/validation_class.*could not be loaded/i, 'class not loaded in message');
        } otherwise {
            fail('other exception thrown');
        };
    };

    ## reset it all, and try a custom validation class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef, 'schema is unset');

    $storage->validation_class('Handel::TestComponents::Validation');
    is($storage->validation_class, 'Handel::TestComponents::Validation', 'validiton class is set');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::Validation'), 'Validation component is loaded');
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::Validation'), 'Validation class is loaded');
    
    is($storage->validation_module, 'FormValidator::Simple', 'validaiton class is set');

    ## throw exception when setting a bogus validation class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->validation_module('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/validation_module.*could not be loaded/i, 'class not loaded in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## throw_exception should put non blessed things in text
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->throw_exception('foo');

            fail('no exception thrown');
        } catch Handel::Exception::Validation with {
            pass('validaiton exception caught');
            like(shift->text, qr/foo/i, 'exception has message in text');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw_exception should put blessed things in results
    {
        my $stuff = bless {-text => 'bar'}, 'Handel::Exception';

        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->throw_exception($stuff);

            fail('no exception thrown');
        } catch Handel::Exception::Validation with {
            pass('validation exception caught');

            my $results = shift->results;
            is(refaddr $results, refaddr $stuff, 'exception stored in result');
            is($results->text, 'bar', 'text was set');
        } otherwise {
            fail('other exception caught');
        };
    };
};

## do the item_storage default_values too
{
    my $validation = [
        sku => ['NOT_BLANK', ['LENGTH', 2, 4]]
    ];

    $storage->schema_instance(undef);
    my $item_storage = Handel::Storage::DBIC->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Items',
        validation_profile => $validation
    });
    $storage->item_storage($item_storage);

    is_deeply($storage->item_storage->validation_profile, $validation, 'validaton profile is set');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Items');
    ok($class->isa('Handel::Components::Validation'), 'Validation component is loaded');

    is_deeply($class->validation_profile, $validation, 'validation profile is loaded');

    ## throw exception when validation fails
    my $item;
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $item = $schema->resultset('Items')->create({
                id => 1,
                cart => 1,
                sku => 'ABC1234567'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Validation with {
            pass('Validation exception caught');
            my $e = shift;
            
            isa_ok($e->results, 'FormValidator::Simple::Results');
            like($e, qr/failed validation/i, 'validaiton failed in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    is($item, undef, 'item is undefined');


    ## item_storage without validaton_profile
    $storage->schema_instance(undef);
    $item_storage->schema_instance(undef);
    $item_storage->validation_profile(undef);
    
    $schema = $storage->schema_instance;

    $class = $schema->class('Items');
    ok(!$class->isa('Handel::Components::Validation'), 'Validation component not loaded');
    is($storage->item_storage->validation_profile, undef, 'validation profile is still undefined');
};
