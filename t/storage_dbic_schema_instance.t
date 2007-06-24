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
        plan tests => 83;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $dsn = Handel::Test->init_schema(no_populate => 1)->dsn;
my $constraints = {
    id   => {'check_id' => sub{}},
    name => {'check_name' => sub{}}
};


## now for an instance
my $storage = Handel::Storage::DBIC->new({
    schema_class       => 'Handel::Cart::Schema',
    schema_source      => 'Carts',
    default_values     => {id => 1, name => 'New Cart'},
    validation_profile => {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]},
    add_columns        => [qw/custom/],
    remove_columns     => [qw/description/],
    constraints        => $constraints,
    currency_columns   => [qw/name/],
    connection_info => [
        $dsn
    ]
});


{
    ## create a new storage and check schema_instance configuration
    isa_ok($storage, 'Handel::Storage');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    my $item_class = $schema->class('Items');
    my $cart_source = $schema->source('Carts');
    my $item_source = $schema->source('Items');

    ## make sure we're running clones unique classes
    like($cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'class is the composed style');
    like($item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is the composed style');

    ## make sure we loaded the validation profile Component and values
    ok($cart_class->isa('Handel::Components::Validation'), 'Validation component is loaded');
    is_deeply($cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]}, 'profile was stored in component');
    ok(!$item_class->isa('Handel::Components::Validation'), 'Validation component still not loaded in item class');

    ## make sure we loaded the default values Component and values
    ok($cart_class->isa('Handel::Components::DefaultValues'), 'Defaults component is loaded');
    is_deeply($cart_class->default_values, {id => 1, name => 'New Cart'}, 'default values was storage in component');
    ok(!$item_class->isa('Handel::Components::DefaultValues'), 'Defaults component still not loaded in item class');

    ## make sure we loaded the constraints Component and values
    ok($cart_class->isa('Handel::Components::Constraints'), 'Constraints component is loaded');
    is_deeply($cart_class->constraints, $constraints, 'constraints stored in component');
    ok(!$item_class->isa('Handel::Components::Constraints'), 'Constraints component still not loaded in item class');

    ## make sure we added/removed columns
    my %columns = map {$_ => 1} $cart_source->columns;
    ok(exists $columns{'custom'}, 'column custom not added');
    ok(!exists $columns{'description'}, 'column description not removed');

    ## make sure we set inflate/deflate
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'inflate'}, 'inflate sub added');
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'deflate'}, 'deflate sub added');

    ## pass in a schema_instance and recheck schema configuration
    my $new_schema = Handel::Cart::Schema->connect($dsn);
    isa_ok($new_schema, 'Handel::Cart::Schema');

    $storage->schema_instance($new_schema);

    $new_schema = $storage->schema_instance;

    my $new_cart_class = $new_schema->class('Carts');
    my $new_item_class = $new_schema->class('Items');
    my $new_cart_source = $new_schema->source('Carts');
    my $new_item_source = $new_schema->source('Items');

    ## make sure we're not the first schema in disguise
    isnt($cart_class, $new_cart_class, 'not original cart class');
    isnt($item_class, $new_item_class, 'not original item class');

    ## make sure we're running clones unique classes
    like($new_cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'class is the composed style');
    like($new_item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is the composed style');

    ## make sure we loaded the validation profile Component and values
    ok($new_cart_class->isa('Handel::Components::Validation'), 'Validation component is loaded');
    is_deeply($new_cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]}, 'validation profile is loaded');
    ok(!$new_item_class->isa('Handel::Components::Validation'), 'Validation component not loaded in item class');

    ## make sure we loaded the default values Component and values
    ok($new_cart_class->isa('Handel::Components::DefaultValues'), 'DefaultValues component is loaded');
    is_deeply($new_cart_class->default_values, {id => 1, name => 'New Cart'}, 'default values are loaded');
    ok(!$new_item_class->isa('Handel::Components::DefaultValues'), 'efaultValues component not loaded in item class');

    ## make sure we loaded the constraints Component and values
    ok($new_cart_class->isa('Handel::Components::Constraints'), 'Constraints component is loaded');
    is_deeply($new_cart_class->constraints, $constraints, 'constraints are loaded');
    ok(!$new_item_class->isa('Handel::Components::Constraints'), 'Constraints component not loaded in item class');

    ## make sure we added/removed columns
    my %new_columns = map {$_ => 1} $new_cart_source->columns;
    ok(exists $new_columns{'custom'}, 'column custom not added');
    ok(!exists $new_columns{'description'}, 'column description not removed');

    ## unset it
    ok($storage->_schema_instance, 'have schema instance');
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef, 'unloaded schema instance');

    ## throw exception if schema_class is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage::DBIC->new({
                schema_source   => 'Carts',
                connection_info => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/no schema_class/i, 'no schema class in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if schema_source is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage::DBIC->new({
                schema_class    => 'Handel::Cart::Schema',
                connection_info => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no schema_source/i, 'no schema source in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if item_relationship is missing
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage::DBIC->new({
                schema_class       => 'Handel::Cart::Schema',
                schema_source      => 'Carts',
                item_storage_class => 'Handel::Storage::DBIC::Cart::Item',
                item_relationship  => 'foo',
                connection_info    => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/no relationship named/i, 'no relationship in message')
        } otherwise {
            fail('other exception caught');
        };
    };
};


## work on class too
{
    Handel::Storage::DBIC->schema_class('Handel::Cart::Schema');
    Handel::Storage::DBIC->schema_source('Carts');
    Handel::Storage::DBIC->constraints($constraints);
    Handel::Storage::DBIC->default_values({id => 1, name => 'New Cart'});
    Handel::Storage::DBIC->validation_profile({cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]});
    Handel::Storage::DBIC->add_columns(qw/custom/);
    Handel::Storage::DBIC->remove_columns(qw/description/);
    Handel::Storage::DBIC->currency_columns(qw/name/);

    my $schema = Handel::Storage::DBIC->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    my $item_class = $schema->class('Items');
    my $cart_source = $schema->source('Carts');
    my $item_source = $schema->source('Items');

    ## make sure we're running clones unique classes
    like($cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'class is the composed style');
    like($item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is the composed style');

    ## make sure we loaded the validation profile Component and values
    ok($cart_class->isa('Handel::Components::Validation'), 'Validation component loaded');
    is_deeply($cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]}, 'validaiton profile loaded');
    ok(!$item_class->isa('Handel::Components::Validation'), 'Validation component no loaded in item class');

    ## make sure we loaded the default values Component and values
    ok($cart_class->isa('Handel::Components::DefaultValues'), 'DefaultValues component is loaded');
    is_deeply($cart_class->default_values, {id => 1, name => 'New Cart'}, 'default values is loaded');
    ok(!$item_class->isa('Handel::Components::DefaultValues'), 'DefaultValues not loaded in item class');

    ## make sure we loaded the constraints Component and values
    ok($cart_class->isa('Handel::Components::Constraints'), 'Constraints component is loaded');
    is_deeply($cart_class->constraints, $constraints, 'constraints are loaded');
    ok(!$item_class->isa('Handel::Components::Constraints'), 'Constraints component not loaded in item class');

    ## make sure we added/removed columns
    my %columns = map {$_ => 1} $cart_source->columns;
    ok(exists $columns{'custom'}, 'column custom not added');
    ok(!exists $columns{'description'}, 'column description not removed');

    ## make sure we set inflate/deflate
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'inflate'}, 'inflate subs loaded');
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'deflate'}, 'deflate subs loaded');

    ## pass in a schema_instance and recheck schema configuration
    my $new_schema = Handel::Cart::Schema->connect($dsn);
    isa_ok($new_schema, 'Handel::Cart::Schema');

    Handel::Storage::DBIC->schema_instance($new_schema);

    $new_schema = Handel::Storage::DBIC->schema_instance;

    my $new_cart_class = $new_schema->class('Carts');
    my $new_item_class = $new_schema->class('Items');
    my $new_cart_source = $new_schema->source('Carts');
    my $new_item_source = $new_schema->source('Items');

    ## make sure we're not the first schema in disguise
    isnt($cart_class, $new_cart_class, 'not original cart class');
    isnt($item_class, $new_item_class, 'not original item class');

    ## make sure we're running clones unique classes
    like($new_cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/, 'class is the composed style');
    like($new_item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/, 'class is the composed style');

    ## make sure we loaded the validation profile Component and values
    ok($new_cart_class->isa('Handel::Components::Validation'), 'Validation component is loaded');
    is_deeply($new_cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]}, 'validation profile is loaded');
    ok(!$new_item_class->isa('Handel::Components::Validation'), 'Validation component not loaded in item class');

    ## make sure we loaded the default values Component and values
    ok($new_cart_class->isa('Handel::Components::DefaultValues'), 'Defaultvalues component is loaded');
    is_deeply($new_cart_class->default_values, {id => 1, name => 'New Cart'}, 'default values are loaded');
    ok(!$new_item_class->isa('Handel::Components::DefaultValues'), 'DefaultValues component is not loaded in item class');

    ## make sure we loaded the constraints Component and values
    ok($new_cart_class->isa('Handel::Components::Constraints'), 'Constraints component is loaded');
    is_deeply($new_cart_class->constraints, $constraints, 'constraints are loaded');
    ok(!$new_item_class->isa('Handel::Components::Constraints'), 'Constraints component is not loaded in item class');

    ## make sure we added/removed columns
    my %new_columns = map {$_ => 1} $new_cart_source->columns;
    ok(exists $new_columns{'custom'}, 'column custom not added');
    ok(!exists $new_columns{'description'}, 'column description not removed');

    ## unset it
    ok(Handel::Storage::DBIC->_schema_instance, 'we have a schema instance');
    Handel::Storage::DBIC->schema_instance(undef);
    is(Handel::Storage::DBIC->_schema_instance, undef, 'schema instance was unloaded');

    ## throw exception if schema_class is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage::DBIC->schema_class(undef);
            Handel::Storage::DBIC->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no schema_class/i, 'no schema class in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if schema_source is empty
    {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage::DBIC->schema_class('Handel::Cart::Schema');
            Handel::Storage::DBIC->schema_source(undef);
            Handel::Storage::DBIC->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no schema_source/i, 'no schema source in message')
        } otherwise {
            fail('other exception caught');
        };
    };

    ## throw exception if item_relationship is missing
    {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage::DBIC->schema_class('Handel::Cart::Schema');
            Handel::Storage::DBIC->schema_source('Carts');
            Handel::Storage::DBIC->item_storage_class('Handel::Storage::DBIC::Cart::Item');
            Handel::Storage::DBIC->item_relationship('foo');
            Handel::Storage::DBIC->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/no relationship named/i, 'no relationship in message')
        } otherwise {
            fail('caught other exception');
        };
    };
};
