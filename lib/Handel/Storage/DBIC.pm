# $Id$
## no critic (ProhibitExcessComplexity)
package Handel::Storage::DBIC;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        _columns_to_add
        _columns_to_remove
        _schema_instance
        connection_info
        item_relationship
        schema_source
        table_name
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        schema_class
        constraints_class
        validation_class
        default_values_class
    /);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed weaken/;
    use Clone ();
};

__PACKAGE__->constraints_class('Handel::Components::Constraints');
__PACKAGE__->default_values_class('Handel::Components::DefaultValues');
__PACKAGE__->item_relationship('items');
__PACKAGE__->iterator_class('Handel::Iterator::DBIC');
__PACKAGE__->result_class('Handel::Storage::DBIC::Result');
__PACKAGE__->validation_class('Handel::Components::Validation');

sub add_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $self->_schema_instance->source($self->schema_source)->add_columns(@columns);
        $self->_schema_instance->class($self->schema_source)->add_columns(@columns);
    };

    $self->_columns_to_add
        ? push @{$self->_columns_to_add}, @columns
        : $self->_columns_to_add(\@columns);

    return;
};

sub add_constraint {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('ADD_CONSTRAINT_EXISTING_SCHEMA')
    ) if $self->_schema_instance; ## no critic

    return $self->SUPER::add_constraint(@_);
};

sub add_item {
    my ($self, $result) = (shift, shift);

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) unless ref($_[0]) eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    my $item = $storage_result->create_related($self->item_relationship, @_);
    my $item_storage = $item->result_source->{'__handel_storage'};

    return $result_class->create_instance(
        $item, $item_storage
    );
};

sub clone {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('NOT_CLASS_METHOD')
    ) unless blessed($self); ## no critic

    # a hack indeed. clone barfs on some DBI inards, so lets move out the
    # schema instance while we clone and put it back
    if ($self->_schema_instance) {
        my $schema = $self->_schema_instance;
        $self->_schema_instance(undef);

        my $clone = $self->SUPER::clone;

        ## filthy hack until I figure out wtf Clone isn't doing in 5.10
        $clone->{'connection_info'} = [@{$self->{'connection_info'} || []}];

        $self->_schema_instance($schema);

        return $clone;
    } else {
        return $self->SUPER::clone;
    };
};

sub column_accessors {
    my $self = shift;
    my $accessors = {};

    if ($self->_schema_instance) {
        my $source = $self->_schema_instance->source($self->schema_source);

        my @columns = $source->columns;
        foreach my $column (@columns) {
            my $accessor = $source->column_info($column)->{'accessor'};
            if (!$accessor) {
                $accessor = $column;
            };
            $accessors->{$column} = $accessor;
        };
    } else {
        my $source = $self->schema_class->source($self->schema_source);

        my @columns = $source->columns;
        foreach my $column (@columns) {
            my $accessor = $source->column_info($column)->{'accessor'};
            if (!$accessor) {
                $accessor = $column;
            };
            $accessors->{$column} = $accessor;
        };

        if ($self->_columns_to_add) {
            # do the DBIC add_column dance step
            my $adding = Clone::clone($self->_columns_to_add);

            while (my $column = shift @{$adding}) {
                my $column_info = ref $adding->[0] ? shift(@{$adding}) : {};
                my $accessor = $column_info->{'accessor'};
                if (!$accessor) {
                    $accessor = $column;
                };
                $accessors->{$column} = $accessor;
            };
        };

        if ($self->_columns_to_remove) {
            foreach my $column (@{$self->_columns_to_remove}) {
                delete $accessors->{$column};
            };
        };
    };

    return $accessors;
};

sub columns {
    my $self = shift;

    if ($self->_schema_instance) {
        return $self->_schema_instance->source($self->schema_source)->columns;
    } else {
        return keys %{$self->column_accessors};
    };
};

sub copyable_item_columns {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_STORAGE_NOT_DEFINED')
    ) unless $self->item_storage; ## no critic

    my $schema_instance = $self->schema_instance;
    my $source = $schema_instance->source($self->schema_source);
    my $item_source = $schema_instance->source($self->item_storage->schema_source);
    my @copyable;
    my %primaries = map {$_ => 1} $item_source->primary_columns;
    my %foreigns;

    if ($source->has_relationship($self->item_relationship)) {
        my @cond = %{$source->relationship_info($self->item_relationship)->{cond}};

        foreach (@cond) {
            if ($_ =~ /^foreign\.(.*)/) {
                $foreigns{$1}++;
            };
        };
    };

    foreach ($item_source->columns) {
        if (!exists $primaries{$_} && !exists $foreigns{$_}) {
            push @copyable, $_;
        };
    };

    return @copyable;
};

sub count_items {
    my ($self, $result) = (shift, shift);

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    return $storage_result->count_related($self->item_relationship, @_);
};

sub create {
    my $self = shift;
    my $schema = $self->schema_instance;
    my $source = $self->schema_source;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($_[0]) eq 'HASH'; ## no critic

    return $result_class->create_instance(
        $schema->resultset($source)->create(@_), $self
    );
};

sub delete {
    my ($self, $filter) = (shift, shift);
    my $schema = $self->schema_instance;
    my $source = $self->schema_source;

    if ($filter) {
        $filter = $self->_migrate_wildcards($filter);
    };

    return $schema->resultset($source)->search($filter, @_)->delete_all;
};

sub delete_items {
    my ($self, $result, $filter) = (shift, shift, shift);

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) unless !$filter || ref $filter eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    my $storage_result = $result->storage_result;
    $filter = $self->_migrate_wildcards($filter) if $filter;

    return $storage_result->delete_related($self->item_relationship, $filter, @_);
};

sub has_column {
    my ($self, $column) = @_;

    if ($self->_schema_instance) {
        return $self->schema_instance->source($self->schema_source)->has_column($column);
    } else {
        return $self->SUPER::has_column($column);
    };
};

sub primary_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        if (@columns) {
            $self->schema_instance->source($self->schema_source)->set_primary_key(@columns);
        };

        return $self->schema_instance->source($self->schema_source)->primary_columns;
    } else {
        if (@columns) {
            $self->_primary_columns(\@columns);
        };

        return $self->_primary_columns ?
            @{$self->_primary_columns} :
            $self->schema_class->source($self->schema_source)->primary_columns;
    };
};

sub remove_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $self->_schema_instance->source($self->schema_source)->remove_columns(@columns);
        $self->_schema_instance->class($self->schema_source)->remove_columns(@columns);
    };

    $self->_columns_to_remove
        ? push @{$self->_columns_to_remove}, @columns
        : $self->_columns_to_remove(\@columns);

    return;
};

sub remove_constraint {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('REMOVE_CONSTRAINT_EXISTING_SCHEMA')
    ) if $self->_schema_instance; ## no critic

    return $self->SUPER::remove_constraint(@_);
};

sub remove_constraints {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('REMOVE_CONSTRAINT_EXISTING_SCHEMA')
    ) if $self->_schema_instance; ## no critic

    return $self->SUPER::remove_constraints(@_);
};

sub schema_instance {
    my $self = shift;
    my $schema_instance = $_[0];
    my $package = ref $self ? ref $self : $self;

    no strict 'refs';

    throw Handel::Exception::Storage(
        -details => translate('SCHEMA_SOURCE_NOT_SPECIFIED')
    ) unless $self->schema_source; ## no critic

    # allow unsetting
    if (scalar @_ && !$schema_instance) {
        return $self->_schema_instance(@_);
    };

    if (blessed $schema_instance) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};

            my $namespace = "$package\:\:".uc($self->new_uuid);
            $namespace =~ s/-//g;

            my $clone_schema = $schema_instance->compose_namespace($namespace);

            $self->_schema_instance($clone_schema);
            $self->_configure_schema_instance;
            $self->set_inherited('schema_class', blessed $clone_schema);
        };
        Class::C3->reinitialize;
    };

    if (!$self->_schema_instance) {
        throw Handel::Exception::Storage(
            -details => translate('SCHEMA_CLASS_NOT_SPECIFIED')
        ) unless $self->schema_class; ## no critic

        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};

            my $namespace = "$package\:\:".uc($self->new_uuid);
            $namespace =~ s/-//g;

            my $clone_schema = $self->schema_class->compose_namespace($namespace);
            my $schema = $clone_schema->connect(@{$self->connection_info || []});

            $self->_schema_instance($schema);
            $self->_configure_schema_instance;
            $self->set_inherited('schema_class', blessed $schema);
        };
        Class::C3->reinitialize;
    };

    return $self->_schema_instance;
};

sub search {
    my ($self, $filter) = (shift, shift);
    my $schema = $self->schema_instance;
    my $source = $self->schema_source;

    if ($filter) {
        $filter = $self->_migrate_wildcards($filter);

        foreach my $key (keys %{$filter}) {
            if ($key !~ /\./) {
                $filter->{"me.$key"} = delete $filter->{$key};
            };
        };
    };

    my $resultset = $schema->resultset($source)->search($filter, @_);
    my $iterator = $self->iterator_class->new({
        data         => $resultset,
        storage      => $self,
        result_class => $self->result_class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub search_items {
    my ($self, $result, $filter) = (shift, shift, shift);

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) if defined $filter && ref $filter ne 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    if ($filter) {
        $filter = $self->_migrate_wildcards($filter);

        foreach my $key (keys %{$filter}) {
            if ($key !~ /\./) {
                $filter->{"me.$key"} = delete $filter->{$key};
            };
        };
    };

    my $resultset = $storage_result->search_related($self->item_relationship, $filter, @_);
    my $item_storage = $resultset->result_source->{'__handel_storage'};

    my $iterator = $self->iterator_class->new({
        data         => $resultset,
        storage      => $item_storage,
        result_class => $item_storage->result_class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub setup {
    my ($self, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($options) eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('SETUP_EXISTING_SCHEMA')
    ) if $self->_schema_instance; ## no critic

    my $schema_instance = delete $options->{'schema_instance'};
    
    # make ->columns/column_accessors w/o happy schema_instance/source
    foreach my $setting (qw/schema_class schema_source/) {
        if (exists $options->{$setting}) {
            $self->$setting(delete $options->{$setting});
        };
    }

    $self->SUPER::setup($options);

    # save the setup for last
    $self->schema_instance($schema_instance) if $schema_instance;

    return;
};

sub txn_begin {
    shift->schema_instance->txn_begin;

    return;
};

sub txn_commit {
    shift->schema_instance->txn_commit;

    return;
};

sub txn_rollback {
    shift->schema_instance->txn_rollback;

    return;
};

sub _configure_schema_instance {
    my ($self) = @_;
    my $schema_instance = $self->schema_instance;
    my $schema_source = $self->schema_source;
    my $iterator_class = $self->iterator_class;
    my $item_storage = $self->item_storage;
    my $item_relationship = $self->item_relationship;
    my $source_class = $schema_instance->class($schema_source);
    my $item_source_class;
    my $source = $schema_instance->source($schema_source);

    ## no critic (ProhibitNoisyQuotes)

    # make this source aware of this storage to make inflate_result happier
    if (blessed $self) {
        $source->{'__handel_storage'} = $self;
        weaken $self;
    };

    # change the table name
    if ($self->table_name) {
        $source->name($self->table_name);
    };

    # change the iterator class
    #$source->resultset_class($iterator_class);

    # twiddle source columns
    if ($self->_columns_to_add) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $source->add_columns(@{$self->_columns_to_add});
        $source_class->add_columns(@{$self->_columns_to_add});
    };
    if ($self->_columns_to_remove) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $source->remove_columns(@{$self->_columns_to_remove});
        $source_class->remove_columns(@{$self->_columns_to_remove});
    };

    # add currency inflate/deflators
    if ($self->currency_columns) {
        my $currency_class = $self->currency_class;
        foreach my $column ($self->currency_columns) {
            next unless $source_class->has_column($column); ## no critic
            $source_class->inflate_column($column, {
                inflate => sub {
                    my ($value, $row) = @_;
                    my $codecolumn = $self->can('currency_code_column')->($self);
                    my $storagecode = $self->can('currency_code')->($self);
                    my $code;
                    if ($codecolumn) {
                        $code = $row->$codecolumn;
                        if (!$code) {
                            $code = $storagecode;
                        };
                    } else {
                        $code = $storagecode;
                    };

                    $currency_class->new(
                        $value,
                        $code,
                        $self->can('currency_format')->($self)
                    );
                },
                deflate => sub {shift->value;}
            });
        };
    };

    if ($item_storage) {
        $item_source_class = $schema_instance->class($item_storage->schema_source);

        throw Handel::Exception::Storage(-text =>
            translate('SCHEMA_SOURCE_NO_RELATIONSHIP', $schema_source, $item_relationship)
        ) unless $source->has_relationship($item_relationship); ## no critic


        my $item_source = $self->schema_instance->source($item_storage->schema_source);
        $item_source->name($item_storage->table_name) if $item_storage->table_name;

        # make this source aware of this storage to make inflate_result happier
        #my $item_storage = $item_class->storage->clone;
        $item_storage->_schema_instance($schema_instance);
        $item_source->{'__handel_storage'} = $item_storage;
        weaken $item_storage;

        

        # twiddle item source columns
        if ($item_storage->_columns_to_add) {
            # I'm still not sure why you have to do both after the result_source_instance
            # fix in compose_namespace.
            $item_source->add_columns(@{$item_storage->_columns_to_add});
            $item_source_class->add_columns(@{$item_storage->_columns_to_add});
        };
        if ($item_storage->_columns_to_remove) {
            # I'm still not sure why you have to do both after the result_source_instance
            # fix in compose_namespace.
            $item_source->remove_columns(@{$item_storage->_columns_to_remove});
            $item_source_class->remove_columns(@{$item_storage->_columns_to_remove});
        };

        # add currency inflate/deflators
        if ($item_storage->currency_columns) {
            my $currency_class = $item_storage->currency_class;
            foreach my $column ($item_storage->currency_columns) {
                next unless $item_source_class->has_column($column); ## no critic
                $item_source_class->inflate_column($column, {
                    inflate => sub {
                        my ($value, $row) = @_;
                        my $codecolumn = $item_storage->can('currency_code_column')->($item_storage);
                        my $storagecode = $item_storage->can('currency_code')->($item_storage);
                        my $code;
                        if ($codecolumn) {
                            $code = $row->$codecolumn;
                            if (!$code) {
                                $code = $storagecode;
                            };
                        } else {
                            $code = $storagecode;
                        };

                        $currency_class->new(
                            $value,
                            $code,
                            $item_storage->can('currency_format')->($item_storage)
                        );
                    },
                    deflate => sub {shift->value;}
                });
            };
        };
    };


    $schema_instance->exception_action(
        sub {
            __PACKAGE__->SUPER::process_error(@_);
        }
    );


    # warning: there be dragons in here
    # load_components/C3 recalc is slow, esp after 6 calls to it
    # this works, evil or not, it works.
    # and it's only evil for schemas who don't load what we need

    # load class and item class validation
    if (my $profile = $self->validation_profile) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $source_class->load_components('+'.$self->validation_class);
        };
        $source_class->validation_profile($profile);
        $source_class->validation_module($self->validation_module);
    };
    if ($item_storage && $item_storage->validation_profile) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $item_source_class->load_components('+'.$item_storage->validation_class);
        };
        $item_source_class->validation_profile(
            $item_storage->validation_profile
        );
        $item_source_class->validation_module(
            $item_storage->validation_module
        );
    };

    # load class and item class constraints
    if (my $constraints = $self->constraints) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $source_class->load_components('+'.$self->constraints_class);
        };
        $source_class->constraints($constraints);
    };
    if ($item_storage && $item_storage->constraints) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $item_source_class->load_components('+'.$item_storage->constraints_class);
        };
        $item_source_class->constraints(
            $item_storage->constraints
        );
    };

    # load class and item class default values
    if (my $defaults = $self->default_values) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $source_class->load_components('+'.$self->default_values_class);
        };
        $source_class->default_values($defaults);
    };
    if ($item_storage && $item_storage->default_values) {
        {
            no warnings 'redefine';
            local *Class::C3::reinitialize = sub {};
            $item_source_class->load_components('+'.$item_storage->default_values_class);
        };
        $item_source_class->default_values(
            $item_storage->default_values
        );
    };

    return;
};

sub _migrate_wildcards {
    my ($self, $filter) = @_;

    return unless $filter; ## no critic

    if (ref $filter eq 'HASH') {
        foreach my $key (keys %{$filter}) {
            my $value = $filter->{$key};
            if (!ref $filter->{$key} && $value =~ /\%/) {
                $filter->{$key} = {like => $value}
            };
        };
    };

    return $filter;
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    $self->SUPER::set_component_class($field, $value);

    if ($field eq 'schema_class') {
        $self->_schema_instance(undef);
    };

    return;
};

sub set_component_data {
    my ($self, $field, $value) = @_;

    if ($self->_schema_instance) {
        throw Handel::Exception::Storage(
            -details => translate('COMPDATA_EXISTING_SCHEMA', $field)
        );
    } else {
        $self->SUPER::set_component_data($field, $value);
    };

    return;
};

1;
__END__

=head1 NAME

Handel::Storage::DBIC - DBIC schema storage layer for cart/order/item reads/writes

=head1 SYNOPSIS

    use MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::DBIC');
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
    
    1;

=head1 DESCRIPTION

Handel::Storage::DBIC is used as an intermediary between Handel::Cart/Handel::Order
and the DBIC schema used for reading/writing to the database.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new instance of Handel::Storage::DBIC, and passes the options to 
L</setup> on the new instance. The three examples below are the same:

    my $storage = Handel::Storage::DBIC-new({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });
    
    my $storage = Handel::Storage::DBIC-new;
    $storage->setup({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });
    
    my $storage = Handel::Storage::DBIC->new;
    $storage->schema_source('Carts');
    $storage->cart_class('CustomCart');

The following additional options are available to new/setup, and take the same
data as their method counterparts:

    connection_info
    constraints_class
    default_values_class
    item_relationship
    schema_class
    schema_instance
    schema_source
    table_name
    validation_class

See L<Handel::Storage/new> a list of other possible options.

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds a list of columns to the current schema_source in the current schema_class
Be careful to always use the column names, not their accessor aliases.

    $storage->add_columns(qw/foo bar baz/);

You can also add columns using the DBIx::Class \%column_info syntax:

    $storage->add_columns(
        foo => {data_type => 'varchar', size => 36},
        bar => {data_type => int, accessor => 'get_bar'}
    );

Yes, you can even mix/match the two:

    $storage->add_columns(
        'foo',
        bar => {accessor => 'get_bar', data_type => 'int'},
        'baz'
    );

Before schema_instance is initialized, the columns to be added are stored
internally, then added to the schema_instance when it is initialized. If a
schema_instance already exists, the columns are added directly to the
schema_source in the schema_instance itself.

See L<Handel::Storage/add_columns> for more information about this method.

=head2 add_constraint

=over

=item Arguments: $column, $name, \&sub

=back

Adds a named constraint for the given column to the current schema_source in the
current schema_class. During insert/update operations, the constraint subs will
be called upon to validation the specified columns data I<after> and default
values are set on empty columns. You can any number of constraints for each
column as long as they all have different names. The constraints may or may not
be called in the order in which they are added.

    $storage->add_constraint('id', 'Check Id Format' => \&constraint_uuid);

Constraints can only be added before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to add a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

See L<Handel::Storage/add_constraint> for more information about this method.

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

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship, has a relationship that can't be
found in the schema, second parameter is not a HASH reference or no result is
specified.

See L<Handel::Storage/add_item> for more information about this method.

=head2 autoupdate

=over

=item Arguments: 0|1

=back

Gets/sets the autoupdate flag for the current schema_source. When set to 1, an
update request will be made to the database for every field change. When set to
0, no updated data will be sent to the database until C<update> is called.

    $storage->autoupdate(1);

The default is 1.

See L<Handel::Storage/autoupdate> for more information about this method.

=head2 clone

Returns a clone of the current storage instance. This is the same as
L<Handel::Storage/clone> except that it disconnects the schema instance before
cloning as DBI hates being cloned apparently.

See L<Handel::Storage/clone> for more information about this method.

=head2 column_accessors

Returns a hashref containing all of the columns and their accessor names for the
current storage object.

If a schema_instance already exists, the columns from schema_source in that
schema_instance will be returned. If no schema_instance exists, the columns from
schema_source in the current schema_class will be returned plus any columns to
be added from add_columns minus and columns to be removed from remove_columns.

See L<Handel::Storage/column_accessors> for more information about this method.

=head2 columns

Returns a list of columns from the current schema source.

See L<Handel::Storage/columns> for more information about this method.

=head2 connection_info

=over

=item Arguments: \@info

=back

Gets/sets the connection information used when connecting to the database.

    $storage->connection_info(['dbi:mysql:foo', 'user', 'pass', {PrintError=>1}]);

The info argument is an array ref that holds the following values:

=over

=item $dsn

The DBI dsn to use to connect to.

=item $username

The username for the database you are connecting to.

=item $password

The password for the database you are connecting to.

=item \%attr

The attributes to be pass to DBI for this connection.

=back

See L<DBI> for more information about dsns and connection attributes.

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

Be careful to always use the column name, not its accessor alias if it has one.

See L<Handel::Storage/constraints> for more information about this method.

=head2 constraints_class

=over

=item Arguments: $constraint_class

=back

Gets/sets the constraint class to be used when check column constraints. The
default constraint class is 
L<Handel::Components::Constraints|Handel::Components::Constraints>. The
constraint class used should be subclass of Handel::Components::Constraints.

    $storage->constraint_class('CustomCurrency');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 copyable_item_columns

Returns a list of columns in the current item class that can be copied freely.
This list is usually all columns in the item class except for the primary
key columns and the foreign key columns that participate in the specified item
relationship.

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if
item class or item relationship are not defined.

See L<Handel::Storage/copyable_item_columns> for more information about this
method.

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

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship or no result is specified.

See L<Handel::Storage/count_items> for more information about this method.

=head2 create

=over

=item Arguments: \%data

=back

Creates a new result in the current source in the current schema.

    my $result = $storage->create({
        col1 => 'foo',
        col2 => 'bar'
    });

This is just a convenience method that does the same thing as:

    my $result = $storage->schema_instance->resultset($storage->schema_source)->create({
        col1 => 'foo',
        col2 => 'bar'
    });

See L<Handel::Storage/create> for more information about this method.

=head2 default_values_class

=over

=item Arguments: $default_values_class

=back

Gets/sets the default values class to be used when setting default column
values. The default class is 
L<Handel::Components::DefaultValues|Handel::Components::DefaultValues>. The
default values class used should be subclass of
Handel::Components::DefaultValues.

    $storage->default_value_class('SetDefaults');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 default_values

=over

=item Arguments: \%values

=back

Gets/sets the hash containing the default values to be applied to empty columns
during insert/update statements. Default values are applied to empty columns
before and constraints or validation occurs.

    $storage->default_values({
        id   => \&newid,
        name => 'My New Cart'
    });

The default values are stored in a hash where the key is the name of the column
and the value is either a reference to a subroutine to get the value from, or
an actual default value itself.

Be careful to always use the column name, not its accessor alias if it has one.

See L<Handel::Storage/default_values> for more information about this method.

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes results matching the filter in the current source in the current schema.

    $storage->delete({
        id => '11111111-1111-1111-1111-111111111111'
    });

This is just a convenience method that does the same thing as:

    $storage->schema_instance->resultset($storage->schema_source)->search({
        id => '11111111-1111-1111-1111-111111111111'
    })->delete_all;

See L<Handel::Storage/delete> for more information about this method.

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

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship.

See L<Handel::Storage/delete_items> for more information about this method.

=head2 has_column

=over

=item Arguments: $column

=back

Returns true if the column exists in the current storage object. If the schema
is already initialized, the has_column method on the result source will be used.
Otherwise, has_column will calculate the existence of the column based on any
current add_columns/remove_columns information.

=head2 item_relationship

=over

=item Arguments: $relationship_name

=back

Gets/sets the name of the schema relationship between carts and items.
The default item relationship is 'items'.

    # in your schema classes
    MySchema::CustomCart->has_many(rel_items => 'MySchema::CustomItem', {'foreign.cart' => 'self.id'});
    
    # in your storage
    $storage->item_relationship('rel_items');

=head2 primary_columns

=over

=item Arguments @columns

=back

Gets/sets the list of primary columns for the current schema source. When the
schema instance exists, the primary columns are added to and returns from the
current schema source on the schema instance.

When no schema instance exists, the columns are set locally like C<add_columns>
then added to the schema instance during its configuration. Primary columns are
returns from the current schema source in the current schema class if no primary
columns have been set locally.

=head2 remove_columns

=over

=item Arguments: @columns

=back

Removes a list of columns from the current schema_source in the current
schema_class and removes the autogenerated accessors from the current class.
Be careful to always use the column names, not their accessor aliases.

    $storage->remove_columns(qw/description/);

Before schema_instance is initialized, the columns to be removed are stored
internally, then removed from the schema_instance when it is initialized. If a
schema_instance already exists, the columns are removed directly from the
schema_source in the schema_instance itself.

See L<Handel::Storage/remove_columns> for more information about this method.

=head2 remove_constraint

=over

=item Arguments: $column, $name

=back

Removes a named constraint for the given column from the current schema_source
in the current schema_class' constraints data structure.

    $storage->remove_constraint('id', 'Check Id Format' => \&constraint_uuid);

Constraints can only be removed before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to remove a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

See L<Handel::Storage/remove_constraint> for more information about this method.

=head2 remove_constraints

=over

=item Arguments: $column

=back

Removes all constraints for the given column from the current schema_source
in the current schema_class' constraints data structure.

    $storage->remove_constraints('id');

Constraints can only be removed before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to remove a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

See L<Handel::Storage/remove_constraints> for more information about this method.

=head2 schema_class

=over

=item Arguments: $schema_class

=back

Gets/sets the schema class to be used for database reading/writing.

    $storage->schema_class('MySchema');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 schema_instance

=over

=item Arguments: $schema_instance

=back

Gets/sets the schema instance to be used for database reading/writing. If no
instance exists, a new one will be created from the specified schema class.

    my $schema = MySchema->connect;
    
    $storage->schema_instance($schema);
    
When a new schema instance is created or assigned, it is cloned and the clone
is altered and used, leaving the original schema untouched.

See L<Handel::Manual::Schema|Handel::Manual::Schema> for more detailed
information about how the schema instance is configured.

=head2 schema_source

=over

=item Arguments: $source_name

=back

Gets/sets the result source name in the current schema class that will be used
to read/write data in the schema.

    $storage->schema_source('Foo');

See L<DBIx::Class::ResultSource/source_name>
for more information about setting the source name of schema classes.
By default, this will be the short name of the schema class in DBIx::Class
schemas.

By default, Handel::Storage looks for the "Carts" source when working with
Handel::Cart, the "Orders" source when working with Handel::Order and the 
"Items" source when working with Cart/Order items.

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

This is just a convenience method that does the same thing as:

    my $resultset = $storage->schema_instance->resultset($storage->schema_source)->search({
        col1 => 'foo'
    });

See L<Handel::Storage/search> for more information about this method.

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

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship.

See L<Handel::Storage/search_items> for more information about this method.

=head2 setup

=over

=item Arguments: \%options

=back

Configures a storage instance with the options specified. Setup accepts the
exact same options that L</new> does.

    package MyStorageClass;
    use strict;
    use warnings;
    use base qw/Handel::Storage::DBIC/;
    
    __PACKAGE__->setup({
        schema_source => 'Foo'
    });
    
    # or
    
    my $storage = Handel::Storage::DBIC-new;
    $storage->setup({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });

This is the same as doing:

    my $storage = Handel::Storage::DBIC-new({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });

If you call setup on a storage instance or class that has already been
configured, its configuration will be updated with the new options. No attempt
will be made to clear or reset the unspecified settings back to their defaults.

If you pass in a schema_instance, it will be assigned last after all of the
other options have been applied.

=head2 table_name

=over

=item Arguments: $table_name

=back

Gets/sets the name of the table in the database to be used for this schema
source.

=head2 txn_begin

Starts a transaction on the current schema instance.

=head2 txn_commit

Commits the current transaction on the current schema instance.

=head2 txn_rollback

Rolls back the current transaction on the current schema instance.

=head2 validation_class

=over

=item Arguments: $validation_class

=back

Gets/sets the validation class to be used when validating column values.
The default class is 
L<Handel::Components::Validation|Handel::Components::Validation>.
The validation class used should be subclass of
Handel::Components::Validation.

    $storage->validation_class('ValidateData');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

See L<Handel::Components::Validation|Handel::Components::Validation> and
L<DBIx::Class::Validation|DBIx::Class::Validation> for more information on to
use data validation.

=head1 SEE ALSO

L<Handel::Storage>, L<Handel::Storage::Result>, L<Handel::Manual::Storage>,
L<Handel::Storage::DBIC::Cart>, L<Handel::Storage::DBIC::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
