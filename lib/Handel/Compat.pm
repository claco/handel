# $Id$
package Handel::Compat;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw/:returnas/;
    use Handel::L10N qw/translate/;
    use Carp qw/cluck/;
    use NEXT;

    cluck translate('COMPAT_DEPRECATED');
};

sub add_columns {
    my $self = shift;
    
    $self->storage->add_columns(@_);

    return;
};

sub add_constraint {
    my ($self, $name, $column, $sub) = @_;
    
    $self->storage->add_constraint($column, $name, $sub);

    return;
};

sub has_wildcard {
    my $filter = shift;

    for (values %{$filter}) {
        return 1 if $_ =~ /\%/;
    };

    return;
};

sub iterator_class {
    my ($self, $iterator_class) = @_;

    if ($iterator_class) {
        $self->storage->iterator_class($iterator_class);
    };

    return $self->storage->iterator_class;
};

sub table {
    my ($self, $table) = @_;

    if ($table) {
        $self->storage->table_name($table);
    };

    return $self->storage->table_name;
};

sub uuid {
    my $class = shift || __PACKAGE__;

    return $class->storage->new_uuid;
};

sub load {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless (ref($filter) eq 'HASH' || !$filter); ## no critic

    $wantiterator ||= RETURNAS_AUTO;

    ## only return array if wantarray and not explicitly asking for an iterator
    ## or we've explicitly asked for a list/array
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @carts = $self->search($filter);
        return @carts;
    ## return an iterator if explicitly asked for
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $self->search($filter);

        return $iterator;
    ## full out auto
    } else {
        my $iterator = $self->search($filter);

        if ($iterator->count == 1) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub items {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless (ref($filter) eq 'HASH' || !$filter); ## no critic

    $wantiterator ||= RETURNAS_AUTO;
    $filter       ||= {};

    ## If the filter as a wildcard, push it through a fresh search_like since it
    ## doesn't appear to be available within a loaded object.
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @items = $self->NEXT::items($filter);

        return @items;
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $self->NEXT::items($filter);

        return $iterator;
    } else {
        my $iterator = $self->NEXT::items($filter);

        if ($iterator->count == 1) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub new {
    my ($self, $data, $process) = @_;

    if ($process) {
        return $self->create($data, {process => $process});
    } else {
        return $self->create($data);
    };
};

sub subtotal {
    my $self = shift;

    if ($self->isa('Handel::Order')) {
        return $self->NEXT::subtotal(@_);
    } else {
        my $storage  = $self->result->storage;
        my $items    = $self->items(undef, 1);
        my $subtotal = 0.00;

        while (my $item = $items->next) {
            $subtotal += ($item->total);
        };

        return $storage->currency_class->new($subtotal);
    };
};

1;
__END__

=head1 NAME

Handel::Compat - Compatibility layer for pre 1.0 subclasses

=head1 SYNOPSIS

    package MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Compat Handel::Cart/;
    
    __PACKAGE__->add_columns(qw/foo bar/);
    
    1;

=head1 DESCRIPTION

Handel::Compat is a thin compatibility layer to ease the process of migrating
existing Cart/Order/Item subclasses. Simply load it before you load the
base class and it will remap your calls to things like
C<add_columns>/C<add_constraints> to the new storage layer.

B<This class is deprecated and will cease to be in some future version. Please
upgrade your code to use Handel::Base and Handel::Storage as soon as possible.>

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds the specified columns to the current storage object. When upgrading,
convert this like so:

    #__PACKAGE__->add_columns(qw/foo bar baz/);
    __PACKAGE__->storage->add_columns(qw/foo bar baz/);

=head2 add_constraint

=over

=item Arguments: $name, $column, \&constraint

=back

Adds a new constraint to the current storage object. When upgrading, convert
this like so:

    #__PACKAGE__->add_constraint('Check Id', id => \&constraint);
    __PACKAGE__->storage->add_constraint('id', 'Check Name', \&constraint);

=head2 cart_class

=over

=item Arguments: $cart_class

=back

Sets the name of the class to be used when returning or creating carts. When
upgrading, convert this like so:

    #__PACKAGE__->cart_class('MyCustomCart');
    __PACKAGE__->storage->cart_class('MyCustomCart');

=head2 item_class

=over

=item Arguments: $item_class

=back

Sets the name of the class to be used when returning or creating cart items.
When upgrading, convert this like so:

    #__PACKAGE__->item_class('MyCustomCart');
    __PACKAGE__->storage->item_class('MyCustomCart');

=head2 items

=over

=item Arguments: \%filter, $wantiterator

=back

You can retrieve all or some of the items contained in the via the C<items>
method. In a scalar context, items returns an iterator object which can be used
to cycle through items one at a time. In list context, it will return an array
containing all items.

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };
    
    my @items = $cart->items;
    ...
    dosomething(\@items);

When filtering the items in the in scalar context, a
item object will be returned if there is only one result. If
there are multiple results, a Handel::Iterator object will be returned
instead. You can force C<items> to always return a Handel::Iterator object
even if only one item exists by setting the $wantiterator parameter to
C<RETURNAS_ITERATOR>.

    my $item = $cart->items({sku => 'SKU1234'}, RETURNAS_ITERATOR);
    if ($item->isa('Handel::Cart::Item)) {
        print $item->sku;
    } else {
        while ($item->next) {
            print $_->sku;
        };
    };

In list context, filtered items return an array of items just as when items is
called without a filter specified.

    my @items - $cart->items((sku -> 'SKU1%'});

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if parameter one isn't a hashref or undef.

=head2 iterator_class

=over

=item Arguments: $iterator_class

=back

Gets/sets the name of the class to be used when iterating through results using
first/next. When upgrading, convert this like so:

    #__PACKAGE__->iterator_class('MyIterator');
    __PACKAGE__->storage->iterator_class('MyIterator');

=head2 load

=over

=item Arguments: \%filter, $wantiterator

=back

Returns cart matching the supplied filter.

    my $cart = Handel::Cart->load({
        id => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

You can also omit \%filter to load all available carts.

    my @carts = Handel::Cart->load();

In scalar context C<load> returns a Handel::Cart object if there is a single
result, or a Handel::Iterator object if there are multiple results. You can
force C<load> to always return an iterator even if only one cart exists by
setting the C<$wantiterator> parameter to C<RETURNAS_ITERATOR>.

    my $iterator = Handel::Cart->load(undef, RETURNAS_ITERATOR);
    while (my $item = $iterator->next) {
        print $item->sku;
    };

See L<Handel::Contstants|Handel::Contstants> for the available
C<RETURNAS> options.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

=head2 new

See L<Handel::Cart/create> and L<Handel::Order/create>.

=head2 subtotal

See L<Handel::Cart/subtotal> and L<Handel::Order/create>

=head2 table

=over

=item Arguments: $table

=back

Gets/sets the name of the table to be used. When upgrading, convert this like
so:

    #__PACKAGE__->table('foo');
    __PACKAGE__->storage->table_name('foo');

=head1 FUNCTIONS

=head2 has_wildcard

=over

=item Arguments: \%filter

=back

Inspects the supplied search filter to determine whether it contains wildcard
searching. Returns 1 if the filter contains SQL wildcards, otherwise it returns
C<undef>.

    has_wildcard({sku => '12%'});  # 1
    has_wildcard((sku => '123'));  # undef

=head2 uuid

Returns a new uuid string. When upgrading, convert this like so:

    #__PACKAGE__->uuid;
    __PACKAGE__->storage->new_uuid;

=head1 SEE ALSO

L<Handel::Base>, L<Handel::Storage>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
