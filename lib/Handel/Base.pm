# $Id$
package Handel::Base;
use strict;
use warnings;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('simple', qw/autoupdate result/);
    __PACKAGE__->mk_group_accessors('inherited', qw/accessor_map/);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        cart_class checkout_class item_class storage_class result_iterator_class
    /);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed weaken refaddr/;
    use Class::ISA;
    use Class::Inspector;
};

__PACKAGE__->storage_class('Handel::Storage');
__PACKAGE__->result_iterator_class('Handel::Iterator::Results');

sub import {
    my $self = shift;

    if (!$self->has_storage) {
        $self->init_storage;
    };

    return;
};

sub create_accessors {
    my ($class, $map) = @_;

    throw Handel::Exception(
        -details => translate('NOT_OBJECT_METHOD')
    ) if blessed($class); ## no critic

    my $accessors = $class->storage->column_accessors || {};
    if (!scalar keys %{$accessors}) {
        throw Handel::Exception(
            -details => translate('NO_COLUMN_ACCESSORS')
        );
    };

    foreach my $column (keys %{$accessors}) {
        $class->mk_group_accessors('column', [$accessors->{$column}, $column]);
    };

    $class->accessor_map($accessors);

    return;
};

sub get_column {
    my $self = shift;

    throw Handel::Exception(
        -details => translate('NOT_CLASS_METHOD')
    ) unless blessed($self); ## no critic

    my $column = shift;
    my $accessor = $self->accessor_map->{$column || ''} || $column;

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless $column; ## no critic

    return $self->result->$accessor;
};

sub set_column {
    my $self = shift;

    throw Handel::Exception(
        -details => translate('NOT_CLASS_METHOD')
    ) unless blessed($self); ## no critic

    my ($column, $value) = @_;
    my $accessor = $self->accessor_map->{$column || ''} || $column;

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless $column; ## no critic

    $self->result->$accessor($value);
    if ($self->autoupdate) {
        $self->update;
    };

    return;
};

sub create_instance {
    my ($self, $result) = @_;
    my $class = blessed $self ? blessed $self : $self;

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage = $result->storage;

    return bless {
        result     => $result,
        autoupdate => $storage->autoupdate,
        storage    => $storage
    }, $class;
};

sub storage {
    my $self = shift;
    my $class = blessed $self ? blessed $self : $self;

    my $args = ref($_[0]) eq 'HASH' ? $_[0] : undef;
    my $storage = blessed($_[0]) && $_[0]->isa('Handel::Storage') ? $_[0] : undef;

    if ($storage) {
        $self->_set_storage($storage);
    } else {
        $storage = $self->_get_storage;
    };

    if (!$storage->_item_storage && $self->item_class) {
        $storage->item_storage($self->item_class->storage);
    };

    if ($args) {
        $storage->setup($args);
    };

    return $storage;
};

sub has_storage {
    my $self = shift;
    my $class = blessed $self ? blessed $self : $self;

    no strict 'refs';

    if ($self->{'storage'} || ${"$class\:\:_storage"}) {
        return 1;
    } else {
        return;
    };
};

sub init_storage {
    shift->_get_storage; ## no critic

    return;
};

sub get_component_class {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "use $value"; ## no critic

            if ($@) {
                throw Handel::Exception::Storage(
                    -details => translate('COMPCLASS_NOT_LOADED', $field, $value)
                );
            };
        };
    };

    $self->set_inherited($field, $value);

    return;
};

sub _get_storage {
    my $self = shift;
    my $class = blessed $self ? blessed $self : $self;

    no strict 'refs';
    no warnings 'once';

    my $storage = $self->{'storage'} || ${"$class\:\:_storage"};
    if (!$storage) {
        my ($super) = (Class::ISA::super_path($class));

        if (${"$super\:\:_storage"}) {
            $storage = ${"$super\:\:_storage"};

            if (blessed($storage) eq $self->storage_class) {
                $storage = $storage->clone;

                # we want our own, not da clones item storage
                if ($storage->_item_storage) {
                    $storage->_item_storage(undef);
                };
            } else {
                $storage = $self->storage_class->new;
            };
        } else {
            $storage = $self->storage_class->new;
        };

        $self->_set_storage($storage);
    };

    return $storage;
};

sub _set_storage {
    my ($self, $storage) = @_;
    my $class = blessed $self ? blessed $self : $self;

    if (blessed $self) {
        $self->{'storage'} = $storage;
    } else {
        no strict 'refs';

        ${"$class\:\:_storage"} = $storage;
    };

    return;
};

sub update {
    my $self = shift;

    return $self->result->update(@_);
};

1;
__END__

=head1 NAME

Handel::Base - Base class for Cart/Order/Item classes

=head1 SYNOPSIS

    use MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->item_class('MyCustomCart::Item');
    
    __PACKAGE__->storage({
        schema_source  => 'Carts',
        constraints    => {
            id         => {'Check Id'      => \&constraint_uuid},
            shopper    => {'Check Shopper' => \&constraint_uuid},
            type       => {'Check Type'    => \&constraint_cart_type},
            name       => {'Check Name'    => \&constraint_cart_name}
        },
        default_values => {
            id         => __PACKAGE__->storage_class->can('new_uuid'),
            type       => CART_TYPE_TEMP
        }
    });
    __PACKAGE__->create_accessors;
    
    1;

=head1 DESCRIPTION

Handel::Base is a base class for the Cart/Order/Item classes that glues those
classes to a L<Handel::Storage|Handel::Storage> object.

=head1 METHODS

=head2 accessor_map

Returns a hashref containing the column/accessor mapping used when
C<create_accessors> was last called. This is used by C<get_column>/C<set_column>
to get the accessor name for any given column.

    $schema->add_column('foo' => {accessor => 'bar');
    ...
    $base->create_accessors;
    $base->bar('newval');  # calls $base->set_column('foo', 'newval');
    ...
    sub set_column {
        my ($self, $column, $value) = @_;
        my $accessor = $self->accessor_map->{$column} || $column;
        
        $self->result->$accessor($value);
    };

=head2 cart_class

=over

=item Arguments: $cart_class

=back

Gets/sets the cart class to be used when creating orders from carts.

    __PACKAGE__->cart_class('CustomCart');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

=head2 checkout_class

=over

=item Arguments: $checkout_class

=back

Gets/sets the checkout class to be used to process the order through the
C<CHECKOUT_PHASE_INITIALIZE> phase when creating a new order and the process
options is set. The default checkout class is
L<Handel::Checkout|Handel::Checkout>.

    __PACKAGE__->checkout_class('CustomCheckout');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

=head2 create_accessors

Creates a column accessor for each accessor returned from
L<Handel::Storage/column_accessors>. If you have defined columns in your
schema to have an accessor that is different than the column name, that will
be used instead of the column name.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    __PACKAGE__->storage->add_columns('foo');
    __PACKAGE__->create_accessors;

Each accessor will call C<get_column>/C<set_column>, passing the real database
column name.

=head2 create_instance

=over

=item Arguments: $result

=back

Creates a new instance of the current class, stores the resultset result object
inside, and does any configuration on the new object before returning it.

    my $result = $storage->create({name => 'My Cart'});
    my $cart = Handel::Cart->create_instance($result);

This is used internally by C<inflate_result> and C<storage>. There's probably
no good reason to use this yourself.

A L<Handel::Exception|Handel::Exception> exception will be
thrown if this method is called on an object. It is a class method only.

=head2 get_column

=over

=item Arguments: $column

=back

Returns the value for the specified column from the current C<result>. If an
accessor has been defined for the column in C<accessor_map>, that will be used
against the result instead.

    my $cart = Handel::Cart->create({name => 'My Cart'});
    print $cart->get_column('name');

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception will be
thrown if no column is specified.

A L<Handel::Exception|Handel::Exception> exception will be
thrown if this method is called on an class. It is an object method only.

=head2 has_storage

Returns true if the current class has an instance of
L<Handel::Storage|Handel::Storage>. Returns undef if it does not.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    if (!__PACKAGE__->has_storage) {
        __PACKAGE->init_storage;
    };

=head2 inflate_result

=over

=item Arguments: $result

=back

This method is called by L<Handel::Iterator|Handel::Iterator> to inflate
objects returned by various iterator operations into the current class. There is
probably no good reason to use this method yourself.

=head2 init_storage

Initializes the storage object in the current class, cloning it from the
superclass if necessary.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    if (!__PACKAGE__->has_storage) {
        __PACKAGE->init_storage;
    };

=head2 item_class

=over

=item Arguments: $item_class

=back

Gets/sets the item class to be used when returning cart/order items.

    __PACKAGE__->item_class('CustomCartItem');

The class specified should be a subclass of Handel::Base, or at least provide
its C<create_instance> and C<result> methods.

A L<Handel::Exception|Handel::Exception> exception will be
thrown if the specified class can not be loaded.

=head2 set_column

=over

=item Arguments: $column, $value

=back

Sets the value for the specified column on the current C<result>. If an
accessor has been defined for the column in C<accessor_map>, that will be used
against the result instead.

    my $cart = Handel::Cart->create({name => 'My Cart'});
    $cart->set_column('name', 'New Cart');

If C<autoupdate> is enable for the current object, C<set_column> will call
C<update> automatically. If C<autoupdate> is disabled, be sure to call C<update>
to save change to the database.

    my $cart = Handel::Cart->create({name => 'My Cart'});
    $cart->set_column('name', 'New Cart');
    if (!$cart->autoupdate) {
        $cart->update;
    };

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception will be
thrown if no column is specified.

A L<Handel::Exception|Handel::Exception> exception will be
thrown if this method is called on an class. It is an object method only.

=head2 storage

=over

=item Arguments: \%options

=back

Returns the local instance of C<storage_class>. If a local object doesn't
exist, it will create and return a new one*. If specified, C<options> will be
passed to C<setup> on the storage object.

B<*> When creating subclasses of Cart/Order/Item classes and no storage object
exists in the current class, storage will attempt to clone one from the
immediate superclass using C<init_storage> and C<clone> first before creating
a new instance. However, a clone will only be created if it is of the same type
specified in C<storage_class>.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    
    my $storage = __PACKAGE__->storage;
    ## clones a new storage object from Handel::Cart

=head2 storage_class

=over

=item Arguments: $storage_class

=back

Gets/sets the default storage class to be created by C<init_storage>.

    __PACKAGE__->storage_class('MyStorage');
    
    print ref __PACKAGE__->storage; # MyStorage

If you are using a custom storage class, you must set C<storage_class> before
you call C<storage> for the first time in this class.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 result

Returns the schema resultset result object for the current class object.
There should be no need currently to access this directly unless you are
writing custom subclasses.

    my @columns = $cart->result->columns;

See L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> and
L<DBIx::Class::Row|DBIx::Class::Row> for more information on using the result
object.

=head2 update

=over

=item Arguments: \%data

=back

Sends all of the column updates to the database. If C<autoupdate> is off in the
current object, you must call this to save your changes or they will
be lost when the object goes out of scope.

    $cart->name('My Cart');
    $cart->description('My Favorite Cart');
    $cart->update;

You may also pass a hash reference containing name/value pairs to be applied:

    $cart->update({
        name        => 'My Cart',
        description => 'My Favorite Cart'
    });

Be careful to always use the column name, not its accessor alias if it has one.

=head2 get_component_class

=over

=item Arguments: $name

=back

Gets the current class for the specified component name.

    my $class = $self->get_component_class('item_class');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_class

=over

=item Arguments: $name, $value

=back

Sets the current class for the specified component name.

    $self->set_component_class('item_class', 'MyItemClass');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

There is no good reason to use this. Use the specific class accessors instead.

=head1 SEE ALSO

L<Handel::Storage>, L<DBIx::Class::ResultSet>, L<DBIx::Class::Row>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
