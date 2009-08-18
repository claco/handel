# $Id$
## no critic (RequireFinalReturn)
package Handel::Storage;
use strict;
use warnings;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    use Scalar::Util qw/reftype blessed/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        _columns
        _primary_columns
        _currency_columns
        currency_code_column
        currency_code
        currency_format
        autoupdate
        uuid_maker
        _item_storage
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        currency_class
        item_storage_class
        iterator_class
        result_class
        validation_module
    /);
    __PACKAGE__->mk_group_accessors('component_data', qw/
        constraints
        default_values
        validation_profile
    /);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
    use DBIx::Class::UUIDColumns;
    use Scalar::Util qw/blessed weaken/;
    use Clone ();
    use Class::Inspector ();
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->currency_class('Handel::Currency');
__PACKAGE__->iterator_class('Handel::Iterator::List');
__PACKAGE__->result_class('Handel::Storage::Result');
__PACKAGE__->validation_module('FormValidator::Simple');
__PACKAGE__->uuid_maker(DBIx::Class::UUIDColumns->uuid_maker);

sub new {
    my $self = bless {}, shift;

    if (scalar @_) {
        $self->setup(@_);
    };

    return $self;
};

sub add_columns {
    my ($self, @columns) = @_;

    $self->_columns([]) unless $self->_columns; ## no critic

    push @{$self->_columns}, @columns;

    return;
};

sub add_constraint {
    my ($self, $column, $name, $constraint) = @_;
    my $constraints = $self->constraints || {};

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless $column; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CONSTRAINT_NAME_NOT_SPECIFIED')
    ) unless $name; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CONSTRAINT_NOT_SPECIFIED')
    ) unless ref $constraint eq 'CODE'; ## no critic

    if (!exists $constraints->{$column}) {
        $constraints->{$column} = {};
    };

    $constraints->{$column}->{$name} = $constraint;

    $self->constraints($constraints);

    return;
};

sub add_item {
    throw Handel::Exception::Virtual;
};

sub check_constraints {
    my ($self, $data, $object) = @_;
    my $constraints = $self->constraints;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    return 1 if !scalar keys(%{$constraints});

    my %failed;

    $object = blessed $object ? $object : $data;

    foreach my $column (keys %{$constraints}) {
        my $value = $data->{$column};
        
        foreach my $name (keys %{$constraints->{$column}}) {
            if (my $sub = $constraints->{$column}->{$name}) {
                if (!$sub->($value, $object, $column, $data)) {
                    $failed{$name} = $column;
                };
            };
        };
    };

    if (scalar keys %failed) {
        my @details = map {"$_(" . $failed{$_} . ')'} keys %failed;

        throw Handel::Exception::Constraint(
            -details => join(', ', @details)
        ); ## no critic;
    } else {
        return 1;
    };
};

sub clone {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('NOT_CLASS_METHOD')
    ) unless blessed($self); ## no critic

    return Clone::clone($self);
};

sub column_accessors {
    my $self = shift;
    my %accessors = map {$_ => $_} $self->columns;

    return \%accessors;
};

sub columns {
    my $self = shift;

    return @{$self->_columns || []};
};

sub copyable_item_columns {
    my $self = shift;
    my $item_storage = $self->item_storage;
    my @columns = $item_storage->columns;
    my %primaries = map {$_ => $_} $item_storage->primary_columns;

    my @remaining;
    foreach my $column (@columns) {
        if (!exists $primaries{$column}) {
            push @remaining, $column;
        };
    };

    return @remaining;
};

sub count_items {
    throw Handel::Exception::Virtual;
};

sub create {
    throw Handel::Exception::Virtual;
};

sub currency_columns {
    my ($self, @columns) = @_;
    my %columns = map {$_ => $_} $self->columns;

    if (@columns) {
        foreach my $column (@columns) {
            throw Handel::Exception::Storage(
                -details => translate('COLUMN_NOT_FOUND', $column)
            ) unless exists $columns{$column}; ## no critic
        };

        $self->_currency_columns(\@columns);
    };

    return @{$self->_currency_columns || []};
};

sub delete {
    throw Handel::Exception::Virtual;
};

sub delete_items {
    throw Handel::Exception::Virtual;
};

sub has_column {
    my ($self, $column) = @_;
    my %columns = map {$_ => $_} $self->columns;

    return exists $columns{$column};
};

sub item_storage {
    my $self = shift;

    if (@_) {
        $self->_item_storage(shift);
    } elsif (!$self->_item_storage && $self->item_storage_class) {
        $self->_item_storage($self->item_storage_class->new);
    };

    return $self->_item_storage;
};

sub new_uuid {
    my $uuid = shift->uuid_maker->as_string;

    $uuid =~ s/^{//;
    $uuid =~ s/}$//;

    return $uuid;
};

sub primary_columns {
    my ($self, @columns) = @_;
    my %columns = map {$_ => $_} $self->columns;

    if (@columns) {
        foreach my $column (@columns) {
            throw Handel::Exception::Storage(
                -details => translate('COLUMN_NOT_FOUND', $column)
            ) unless exists $columns{$column}; ## no critic
        };

        $self->_primary_columns(\@columns);
    };

    return @{$self->_primary_columns || []};
};

sub process_error { ## no critic (RequireFinalReturn)
    my ($self, $message) = @_;

    if (blessed $message && $message->isa('Handel::Exception')) {
        die $message; ## no critic
    };

    if ($message =~ /column(s){0,1}\s+(.*)\s+(is|are) not unique/) {
        my $details = translate('COLUMN_VALUE_EXISTS', $2); ## no critic

        throw Handel::Exception::Constraint(-text => $details);
    } elsif ($message =~ /\s*(.*)\s+value already exists/) {
        my $details = translate('COLUMN_VALUE_EXISTS', $1); ## no critic

        throw Handel::Exception::Constraint(-text => $details);
    } else {
        throw Handel::Exception::Storage(-text => "$message");
    };
};

sub remove_columns {
    my ($self, @columns) = @_;
    my %remove = map {$_ => $_} @columns;

    return unless scalar @columns; ## no critic

    if ($self->primary_columns) {
        # remove primary
        my @remaining_primary;
        foreach my $column ($self->primary_columns) {
            if (!exists $remove{$column}) {
                push @remaining_primary, $column;
            };
        };

        # clear/push to keep same array ref
        @{$self->_primary_columns} = ();
        push @{$self->_primary_columns}, @remaining_primary;
    };
    if ($self->currency_columns) {
        # remove currency
        my @remaining_currency;
        foreach my $column ($self->currency_columns) {
            if (!exists $remove{$column}) {
                push @remaining_currency, $column;
            };
        };

        # clear/push to keep same array ref
        @{$self->_currency_columns} = ();
        push @{$self->_currency_columns}, @remaining_currency;
    };
    if ($self->columns) {
        # remove columns
        my @remaining;
        foreach my $column ($self->columns) {
            if (!exists $remove{$column}) {
                push @remaining, $column;
            };
        };

        # clear/push to keep same array ref
        @{$self->_columns} = ();
        push @{$self->_columns}, @remaining;
    };

    return;
};

sub remove_constraint {
    my ($self, $column, $name) = @_;
    my $constraints = $self->constraints;

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless defined $column; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CONSTRAINT_NAME_NOT_SPECIFIED')
    ) unless defined $name; ## no critic

    return unless $constraints; ## no critic

    if (exists $constraints->{$column} && exists $constraints->{$column}->{$name}) {
        delete $constraints->{$column}->{$name};
        if (! keys %{$constraints->{$column}}) {
            delete $constraints->{$column};
        };
    };

    $self->constraints($constraints);

    return;
};

sub remove_constraints {
    my ($self, $column) = @_;
    my $constraints = $self->constraints;

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless defined $column; ## no critic

    return unless $constraints;

    if (exists $constraints->{$column}) {
        delete $constraints->{$column};
    };

    $self->constraints($constraints);

    return;
};

sub search {
    throw Handel::Exception::Virtual;
};

sub search_items {
    throw Handel::Exception::Virtual;
};

sub set_default_values {
    my ($self, $data) = @_;
    my $defaults = $self->default_values;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    return unless (defined $defaults && reftype($defaults) eq 'HASH'); ## no critic

    foreach my $default (keys %{$defaults}) {;
        if (!defined $data->{$default}) {
            my $value = $defaults->{$default};
            my $new_value;

            if (reftype($value) && reftype($value) eq 'CODE') {
                $new_value = $value->($self);
            } elsif (!reftype($value)) {
                $new_value = $value;
            } else {
                next;
            };

            $data->{$default} = $new_value;
        };
    };

    return;
};

sub setup {
    my ($self, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($options) eq 'HASH'; ## no critic

    ## do these in order
    foreach my $setting (qw/add_columns remove_columns primary_columns currency_columns/) {
        if (exists $options->{$setting}) {
            $self->$setting( @{delete $options->{$setting}} );
        };
    };

    foreach my $key (keys %{$options}) {
        if ($self->can($key)) {
            $self->$key($options->{$key});
        } else {
            $self->{$key} = $options->{$key};
        };
    };

    return;
};

sub txn_begin {
    throw Handel::Exception::Virtual;
};

sub txn_commit {
    throw Handel::Exception::Virtual;
};

sub txn_rollback {
    throw Handel::Exception::Virtual;
};

sub validate_data {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    my $module = $self->validation_module;
    my $profile = $self->validation_profile;

    return unless $profile; ## no critic

    if ($module->isa('FormValidator::Simple') && ref $profile ne 'ARRAY') {
        throw Handel::Exception::Storage(
            -text => translate('FVS_REQUIRES_ARRAYREF')
        );
    } elsif ($module->isa('Data::FormValidator') && ref $profile ne 'HASH') {
        throw Handel::Exception::Storage(
            -text => translate('DFV_REQUIRES_HASHREF')
        );
    };

    return $module->check($data => $profile);
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

            throw Handel::Exception::Storage(
                -details => translate('COMPCLASS_NOT_LOADED', $field, $value)
            ) if $@; ## no critic
        };
    };

    $self->set_inherited($field, $value);

    return;
};

sub get_component_data {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_data {
    my ($self, $field, $value) = @_;

    $self->set_inherited($field, $value);

    return;
};

1;
__END__

=head1 NAME

Handel::Storage - Abstract storage layer for cart/order/item reads/writes

=head1 SYNOPSIS

    package MyStorage;
    use strict;
    use warnings;
    use base qw/Handel::Storage/;

    sub create {
        my ($self, $data) = @_;

        return $self->result_class->create_instance(
            $ldap->magic($data), $self
        );
    };
    
    package MyCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('MyStorage');
    __PACKAGE__->storage({
        columns         => [qw/id foo bar baz/],
        primary_columns => [qw/id/]
    });
    
    1;

=head1 DESCRIPTION

Handel::Storage is a base class used to create custom storage classes used by
cart/order/item classes. It provides some generic functionality as well as
methods that must be implemented by custom storage subclasses like
Handel::Storage::DBIC.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new instance of Handel::Storage, and passes the options to L</setup>
on the new instance. The three examples below are the same:

    my $storage = Handel::Storage-new({
        item_class => 'Handel::Item'
    });
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        item_class => 'Handel::Item'
    });
    
    my $storage = Handel::Storage->new;
    $storage->item_class('Handel::Item')

The following options are available to new/setup, and take the same data as
their method counterparts:

    add_columns
    autoupdate
    constraints
    currency_class
    currency_columns
    currency_code
    currency_code_column
    currency_format
    default_values
    item_class
    iterator_class
    primary_columns
    remove_columns
    result_class
    validation_module
    validation_profile

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds a list of columns to the current storage object.

    $storage->add_columns('quix');

=head2 add_constraint

=over

=item Arguments: $column, $name, \&sub

=back

Adds a named constraint for the given column to the current storage object.
You can have any number of constraints for each column as long as they all have
different names. The constraints may or may not be called in the order in which
they are added.

    $storage->add_constraint('id', 'Check Id Format' => \&constraint_uuid);

B<It is up to each custom storage class to decide if and how to implement column
constraints.>

=head2 add_item

=over

=item Arguments: $result, \%data

=back

Adds a new item to the specified result, returning a storage result object.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $item = $storage->add_item($result, {
        sku => 'ABC123'
    });
    
    print $item->sku;

B<This method must be implemented in custom subclasses.>

=head2 autoupdate

=over

=item Arguments: 0|1

=back

Gets/sets the autoupdate flag for the current storage object. When set to 1, an
update request will be made to storage for every column change. When set to
0, no updated data will be sent to storage until C<update> is called.

    $storage->autoupdate(1);

The default is 1.

B<It is up to each custom storage class to decide if and how to implement
autoupdates.>

=head2 check_constraints

=over

=item Arguments: \%data

=back

Runs the configured constraints against C<data> and returns true if the data
passes all current constraints. Otherwise, a
L<Handel::Exception::Constraint|Handel::Exception::Constraint> exception is
thrown.

    $storage->constraints({
        id   => {'Check Id Format' => \&constraint_uuid},
        name => {'Check Name/Type' => \%constraint_cart_type}
    });
    
    my $data = {id => 'abc'};
    
    $storage->check_constraints($data);

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception is thrown
if the first parameter is not a HASHREF.

=head2 clone

Returns a clone of the current storage instance.

    $storage->item_class('Item');
    $storage->cart_class('Cart');
    
    my $clone = $storage->clone;
    $clone->item_class('Bar');
    
    print $storage->item_class; # Item
    print $clone->item_class;   # Item
    print $clone->cart_class;   $ Cart

This is used mostly between sub/super classes to inherit a copy of the storage
settings without having to specify options from scratch.

=head2 column_accessors

Returns a hashref containing all of the columns and their accessor names for the
current storage object.

    $storage->add_columns(qw/foo bar/);
    print %{$self->column_accessors});
    # foo foo bar bar

The column accessors are used by cart/order/item classes to map public accessors
to their columns.

=head2 columns

Returns a list of columns from the current storage object;

    $storage->add_columns(qw/foo bar baz/);
    print $storage->columns;  # foo bar baz

=head2 constraints

=over

=item Arguments: \%constraints

=back

Gets/sets the constraints configuration for the current storage instance.

    $storage->constraints({
        id   => {'Check Id Format' => \&constraint_uuid},
        name => {'Check Name/Type' => \%constraint_cart_type}
    });

The constraints are stored in a hash where each key is the name of the column
and each value is another hash reference containing the constraint name and the
constraint subroutine reference.

B<It is up to each custom storage class to decide if and how to implement column
constraints.>

=head2 copyable_item_columns

Returns a list of columns in the current item class that can be copied freely.
This list is usually all columns in the item class except for the primary
key columns and the foreign key columns that participate in the specified item
relationship.

=head2 count_items

=over

=item Arguments: $result

=back

Returns the number of items associated with the specified result.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    print $storage->count_items($result);

B<This method must be implemented in custom subclasses.>

=head2 create

=over

=item Arguments: \%data

=back

Creates a new result in the current storage medium.

    my $result = $storage->create({
        col1 => 'foo',
        col2 => 'bar'
    });

B<This method must be implemented in custom subclasses.>

=head2 currency_class

=over

=item Arguments: $currency_class

=back

Gets/sets the currency class to be used when inflating currency columns. The
default currency class is L<Handel::Currency|Handel::Currency>. The currency
class used should be subclass of Handel::Currency.

    $storage->currency_class('CustomCurrency');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

B<It is up to each custom storage class to decide if and how to implement
currency columns.>

=head2 currency_columns

=over

=item Arguments: @columns

=back

Gets/sets the columns that should be inflated into currency objects.

    $storage->currency_columns(qw/total price tax/);

B<It is up to each custom storage class to decide if and how to implement
currency columns.>

=head2 currency_code

=over

=item $code

=back

Gets/sets the currency code used by default when formatting currency objects.

See L<Locale::Currency::Format|Locale::Currency::Format> and
L<Locale::Currency|Locale::Currency> for the list of available currency codes.

=head2 currency_code_column

=over

=item Arguments: $column

=back

Gets/sets the name of the column that contains the currency code to be used
for the current row. If no column is specified or it is empty, C<currency_code>
will be used instead.

B<It is up to each custom storage class to decide if and how to implement
currency columns.>

=head2 currency_format

=over

=item $format_options

=back

Gets/sets the currency formatting options used by default when formatting
currency objects.

See L<Locale::Currency::Format|Locale::Currency::Format> and
L<Locale::Currency|Locale::Currency> for the list of available currency codes.

=head2 default_values

=over

=item Arguments: \%values

=back

Gets/sets the hash containing the default values to be applied to empty columns
during create/update actions.

    $storage->default_values({
        id   => \&newid,
        name => 'My New Cart'
    });

The default values are stored in a hash where the key is the name of the column
and the value is either a reference to a subroutine to get the value from, or
an actual default value itself.

B<It is up to each custom storage class to decide if and how to implement
default values.>

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes results matching the filter in the current storage medium.

    $storage->delete({
        id => '11111111-1111-1111-1111-111111111111'
    });

B<This method must be implemented in custom subclasses.>

=head2 delete_items

=over

=item Arguments: $result, \%filter

=back

Deletes items matching the filter from the specified result.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $storage->delete_items($result, {
        sku => 'ABC%'
    });

B<This method must be implemented in custom subclasses.>

=head2 has_column

=over

=item Arguments: $column

=back

Returns true if the column exists in the current storage object.

=head2 item_storage_class

=over

=item Arguments: $item_storage_class

=back

Gets/sets the item storage class used to hold item storage configuration and/or
create cart/order items.

    my $storage = My::Storage::Cart->new;
    $storage->item_storage_class('My::Storage::Cart::Item');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 item_storage

=over

=item Arguments: $storage

=back

Gets/sets the storage objects used to hold item storage configuration options
and/or create item storage results. If no storage object is assigned, one will
be created using the specified C<item_storage_class>.

    $storage->item_storage_class('My::Storage::Cart::Item');
    my $item_storage = $storage->item_storage;
    
    print ref $item_storage;  # My::Storage::Cart:Item

    my $storage = My::Storage::Order->new;
    my $item_storage = My::Storage::Order::Item->new;
    
    $storage->item_storage($item_storage);

=head2 iterator_class

=over

=item $iterator_class

=back

Gets/sets the class used for iterative result operations. The default
iterator is L<Handel::Iterator::List|Handel::Iterator::List>.

    $storage->iterator_class('MyIterator');
    my $results = $storage->search;
    
    print ref $results # Handel::Iterator::List

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 new_uuid

Returns a new uuid/guid string in the form of

    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

See L<DBIx::Class::UUIDColumns|DBIx::Class::UUIDColumns> for more information on
how uuids are generated.

=head2 primary_columns

Returns a list of primary columns from the current storage object;

    $storage->add_columns(qw/foo bar baz/);
    $storage->primary_columns('foo');
    print $storage->primary_columns;  # foo

=head2 process_error

=over

=item Arguments: $message

=back

This method accepts errors and converts them
into Handel::Exception objects before throwing the error.

If C<message> already a blessed object, it is just re thrown.

=head2 remove_columns

=over

=item Arguments: @columns

=back

Removes a list of columns from the current storage object.

    $storage->remove_columns(qw/description/);

=head2 remove_constraint

=over

=item Arguments: $column, $name

=back

Removes a named constraint for the given column from the current storage object.

    $storage->remove_constraint('id', 'Check Id Format' => \&constraint_uuid);

=head2 remove_constraints

=over

=item Arguments: $column

=back

Removes all constraints for the given column from the current storage object.

    $storage->remove_constraints('id');

=head2 result_class

=over

=item Arguments: $result_class

=back

Gets/sets the result class to be used when returning results from create/search
storage operations. The default result class is
L<Handel::Storage::Result|Handel::Storage::Result>.

    $storage->result_class('CustomStorageResult');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 search

=over

=item Arguments: \%filter

=back

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

    my $iterator = $storage->search({
        col1 => 'foo'
    });

    my @results = $storage->search({
        col1 => 'foo'
    });

B<This method must be implemented in custom subclasses.>

=head2 search_items

=over

=item Arguments: $result, \%filter

=back

Returns items matching the filter associated with the specified result.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->search({
        id => '11111111-1111-1111-1111-111111111111'
    });
    
    my $iterator = $storage->search_items($result);

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

B<This method must be implemented in custom subclasses.>

=head2 set_default_values

=over

=item Arguments: \%data

=back

Sets the default values on any column that is not already defined using the
values defined in C<default_values>.

    $self->default_values({
        col1 => 'foo',
        col2 => sub {'stuff'},
        col3 => 2
    });
    
    my $data = {col3 => 4};
    $self->set_default_values($data);

    print %{$data};
    
    # {
    #     col1 => 'foo',
    #     col2 => 'stuff',
    #     col3 => 2
    # }

=head2 setup

=over

=item Arguments: \%options

=back

Configures a storage instance with the options specified. Setup accepts the
exact same options that L</new> does.

    package MyStorageClass;
    use strict;
    use warnings;
    use base qw/Handel::Storage/;
    
    __PACKAGE__->setup({
        item_class => 'Foo'
    });
    
    # or
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        item_class => 'Items',
        cart_class => 'CustomerCart'
    });

This is the same as doing:

    my $storage = Handel::Storage-new({
        item_class => 'Items',
        cart_class => 'CustomerCart'
    });

If you call setup on a storage instance or class that has already been
configured, its configuration will be updated with the new options. No attempt
will be made to clear or reset the unspecified settings back to their defaults.

=head2 txn_begin

Starts a transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 txn_commit

Commits the current transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 txn_rollback

Rolls back the current transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 validate_data

=over

=item Arguments: \%data

=back

Validates the specified data against the current <validation_profile> and
returns the validation result using the specified C<validation_module>.

    $self->validation_profile([
        col1 => [ ['NOT_BLANK'] ]
    ]);
    
    my $data = {col1 => ''};
    
    my $results = $self->validate_data($data);
    if ($results->success) {
        ...
    };

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception is thrown
if validation module is set to FormValidator::Simple and the validation
profile isn't a ARRAYREF, or the validation module is set to Data::FormValidator
and the validation profile isn't a HASHREF.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception is thrown
if the first parameter is not a HASHREF.

=head2 validation_module

=over

=item Arguments: $validation_module

=back

Gets/sets the module validation class should use to do its column data
validation. The default module is FormValidator::Simple. 

And validation module may be used that supports the check method.

B<It is up to each custom storage class to decide if and how to implement data
validation.>

=head2 validation_profile

=over

=item Arguments: \@profile*

=back

Gets/sets the validation profile to be used when validating column values.

    $storage->validation_profile([
        param1 => ['NOT_BLANK', 'ASCII', ['LENGTH', 2, 5]],
        param2 => ['NOT_BLANK', 'INT'  ],
        mail1  => ['NOT_BLANK', 'EMAIL_LOOSE']
    ]);

B<*> The default validation module is
L<FormValidator::Simple|FormValidator::Simple>, which expects a profile in an
array reference. If you use L<Data::FormValidator|Data::FormValidator>, make
sure you pass in the profile as a hash reference instead:

    $storage->validation_profile({
        optional => [qw( company
                         fax 
                         country )],
        required => [qw( fullname 
                         phone 
                         email 
                         address )]
    });

B<It is up to each custom storage class to decide if and how to implement data
validation.>

=head2 get_component_data

=over

=item Arguments: $data

=back

Gets the current data for the specified component name.

    my $profile = $self->get_component_data('validation_profile');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_data

=over

=item Arguments: $name, $data

=back

Sets the current class for the specified component name.

    $self->set_component_data('validation_profile', [name => ['NOT_BLANK']]);

There is no good reason to use this. Use the specific class accessors instead.

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

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

There is no good reason to use this. Use the specific class accessors instead.

=head1 SEE ALSO

L<Handel::Storage::DBIC>, L<Handel::Storage::Result>,
L<Handel::Manual::Storage>, L<Handel::Storage::DBIC::Cart>,
L<Handel::Storage::DBIC::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
