#!perl -wT
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
        plan tests => 79;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $constraints = {
    'name'        => {'check_name' => \&check_name, 'no_coderef' => undef},
    'description' => {'check_description' => \&check_description}
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    constraints     => $constraints,
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->constraints, $constraints, 'constraints were set');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::Constraints'), 'constraints component is loaded');

    is_deeply($class->constraints, $constraints, 'constraints were loaded');

    my $cart = $schema->resultset('Carts')->create({
        id => 1,
        shopper => 2,
        name => 'test',
        description => 'Christopher Laco'
    });
    is($cart->name, 'test', 'got name');
    is($cart->description, 'ChristopherLaco', 'got altered description');


    ## throw exception for bogus name
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $cart->name('12345');
            $cart->update;

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('constraint exception caught');
            like(shift, qr/failed.*check_name/, 'check_name failed in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## update works just dandy with the right data
    $cart->name('123');
    $cart->update;
    is($cart->name, '123', 'name was updated');


    ## remove the constraints from source, and try again
    $schema->class('Carts')->constraints(undef);
    $cart->name('123456');
    $cart->update;
    is($cart->name, '123456', 'name was updated');


    my $constraint = sub{};
    $class->add_constraint('id', 'check id' => $constraint);
    is_deeply($class->constraints, {id => {'check id' => $constraint}}, 'constraints were set');

    my $new_constraint = sub{};
    $class->add_constraint('name', 'first' => $new_constraint);
    $class->add_constraint('name', 'second' => $new_constraint);

    is_deeply($class->constraints, {'id' => {'check id' => $constraint}, 'name' => {first => $new_constraint, second => $new_constraint}}, 'constraints were loaded');


    ## throw exception when no column is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->add_constraint(undef, second => sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('argument exception caught');
            like(shift, qr/no column/i, 'no column in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception when no name is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->add_constraint('id', undef, sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('argument exception caught');
            like(shift, qr/no constraint name/i, 'no constraint in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception when no constraint is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->add_constraint('id', 'second' => undef);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('argument exception caught');
            like(shift, qr/no constraint/i, 'no constraint in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception when non-CODEREF is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $class->add_constraint('id', 'second' => []);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('argument exception caught');
            like(shift, qr/no constraint/i, 'no constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };


    ## throw exception when setting a constraints with open schema_instance
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->constraints({
                field => {'do_field' => sub{}}
            });

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/existing schema/, 'existing schema instance in message');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## throw exception when setting a bogus constraint class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->constraints_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception thrown');
            like(shift, qr/constraints_class.*could not be loaded/, 'constraint class in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    ## reset it all, and try a custom constraints class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef, 'unset schema instance');

    $storage->constraints_class('Handel::TestComponents::Constraints');
    is($storage->constraints_class, 'Handel::TestComponents::Constraints', 'set constraints class');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::Constraints'), 'constraints class is set');
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::Constraints'), 'Constraints component is loaded');
};


## do the item_storage default_values too
{
    my $constraints = {
        'sku' => {'check_sku' => \&check_sku, 'no_coderef' => undef}
    };

    $storage->schema_instance(undef);
    my $item_storage = Handel::Storage::DBIC->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Items',
        constraints     => $constraints
    });
    $storage->item_storage($item_storage);

    is_deeply($storage->item_storage->constraints, $constraints, 'constraints were loaded');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Items');
    ok($class->isa('Handel::Components::Constraints'), 'Constraints component is loaded');

    is_deeply($class->constraints, $constraints, 'constraints were loaded');

    my $item = $schema->resultset('Items')->create({
        id => 1,
        cart => 1,
        sku => 'ABC'
    });
    is($item->sku, 'ABC', 'got sku');


    ## throw exception for bogus sku
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $item->sku('12345');
            $item->update;

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('constraint exception caught');
            like(shift, qr/failed.*constraint.*check_sku/, 'check_sku failed in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## update works just dandy with the right data
    $item->sku('DEF');
    $item->update;
    is($item->sku, 'DEF', 'sku was updated');


    ## remove the constraints from source, and try again
    $schema->class('Items')->constraints(undef);
    $item->sku('123456');
    $item->update;
    is($item->sku, '123456', 'sku was updated');



    ## item_storage without default_values
    $storage->schema_instance(undef);
    $item_storage->schema_instance(undef);
    $item_storage->constraints(undef);
    
    $schema = $storage->schema_instance;

    $class = $schema->class('Items');
    ok(!$class->isa('Handel::Components::Constraints'), 'Constraints component is not loaded');
    is($storage->item_storage->constraints, undef, 'constraints are still undefined');
};


sub check_name {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    ok($value, 'got value');
    isa_ok($object, 'DBIx::Class::ResultSource::Table');
    is($column, 'name', 'got column name');
    isa_ok($changing, 'HASH');

    return $value =~ /^.{2,4}$/;
};

sub check_sku {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    ok($value, 'got value');
    isa_ok($object, 'DBIx::Class::ResultSource::Table');
    is($column, 'sku', 'got column sku');
    isa_ok($changing, 'HASH');

    return $value =~ /^.{2,4}$/;
};

sub check_description {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    ok($value, 'got value');
    isa_ok($object, 'DBIx::Class::ResultSource::Table');
    is($column, 'description', 'got column description');
    isa_ok($changing, 'HASH');

    $value =~ s/\s+//g;
    $changing->{$column} = $value;

    return 1;
};
