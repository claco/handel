# $Id$
package Handel::Cart;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw/:cart/;
    use Handel::Constraints qw/:all/;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed/;

    use base qw/Handel::Base/;
    __PACKAGE__->item_class('Handel::Cart::Item');
    __PACKAGE__->storage_class('Handel::Storage::DBIC::Cart');
    __PACKAGE__->create_accessors;
};

sub create {
    my ($self, $data, $opts) = @_;

    if (ref $data ne 'HASH') {
        throw Handel::Exception::Argument(
            -details => translate('PARAM1_NOT_HASHREF')
        );
    };

    no strict 'refs';
    my $storage = $opts->{'storage'};
    if (!$storage) {
        $storage = $self->storage;
    };

    return $self->create_instance(
        $storage->create($data)
    );
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate('PARAM1_NOT_HASHREF_CARTITEM')
    ) unless (ref($data) eq 'HASH' or $data->isa('Handel::Cart::Item')); ## no critic

    my $result = $self->result;
    my $storage = $result->storage;

    if (ref($data) eq 'HASH') {
        return $self->item_class->create_instance(
            $result->add_item($data)
        );
    } else {
        my %copy;

        foreach ($storage->copyable_item_columns) {
            if ($data->can($_)) {
                $copy{$_} = $data->$_;
            } elsif ($data->result->can($_)) {
                $copy{$_} = $data->result->$_;
            };
        };

        return $self->item_class->create_instance(
            $result->add_item(\%copy)
        );
    };
};

sub clear {
    my $self = shift;

    return $self->result->delete_items;
};

sub count {
    my $self = shift;

    return $self->result->count_items;
};

sub delete {
    my ($self, $filter) = @_;

    if (ref $filter ne 'HASH') {
        throw Handel::Exception::Argument(
            -details => translate('PARAM1_NOT_HASHREF')
        );
    };

    return $self->result->delete_items($filter);
};

sub destroy {
    my ($self, $filter, $opts) = @_;

    if (blessed $self && !defined $filter) {
        my $result = $self->result->delete;
        if ($result) {
            undef ($self);
        };
        return $result;
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('PARAM1_NOT_HASHREF')
        ) unless ref($filter) eq 'HASH'; ## no critic

        no strict 'refs';
        my $storage = $opts->{'storage'};
        if (!$storage) {
            $storage = $self->storage;
        };

        return $storage->delete($filter);
    };
};

sub items {
    my ($self, $filter, $opts) = @_;
    my $result = $self->result;
    my $storage = $result->storage;

    $filter ||= {};
    $opts ||= {};

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless ref($filter) eq 'HASH'; ## no critic

    throw Handel::Exception::Argument( -details =>
        translate('PARAM2_NOT_HASHREF')
    ) unless ref($opts) eq 'HASH'; ## no critic

    my $results = $result->search_items($filter, $opts);
    my $iterator = $self->item_class->result_iterator_class->new({
        data         => $results,
        result_class => $self->item_class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub search {
    my ($self, $filter, $opts) = @_;
    my $class = blessed $self ? blessed $self : $self;

    $filter ||= {};
    $opts ||= {};

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless ref($filter) eq 'HASH'; ## no critic

    throw Handel::Exception::Argument( -details =>
        translate('PARAM2_NOT_HASHREF')
    ) unless ref($opts) eq 'HASH'; ## no critic

    my $storage = delete $opts->{'storage'};
    if (!$storage) {
        $storage = $self->storage;
    };

    my $results = $storage->search($filter, $opts);
    my $iterator = $self->result_iterator_class->new({
        data         => $results,
        result_class => $class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub restore {
    my ($self, $data, $mode) = @_;

    $mode ||= CART_MODE_REPLACE;

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF_CART')
    ) unless (ref($data) eq 'HASH' || $data->isa('Handel::Cart')); ## no critic

    my @carts = (ref($data) eq 'HASH') ?
        $self->search($data)->all : $data;

    if ($mode == CART_MODE_REPLACE) {
        $self->clear;

        my $first = $carts[0];

        ## this is hacky..needs to be more generic
        ## since neither could have them, or rename them
        if ($self->can('name') && $first->can('name')) {
            $self->name($first->name);
        };
        if ($self->can('description') && $first->can('description')) {
            $self->description($first->description);
        };

        foreach my $cart (@carts) {
            my @items = $cart->items->all;
            foreach my $item (@items) {
                $self->add($item);
            };
        };
    } elsif ($mode == CART_MODE_MERGE) {
        foreach my $cart (@carts) {
            my @items = $cart->items->all;
            foreach my $item (@items) {
                if (my $exists = $self->items({sku => $item->sku})->first) {
                    $exists->update({
                        quantity => $item->quantity + $exists->quantity
                    });
                } else {
                    $self->add($item);
                };
            };
        };
    } elsif ($mode == CART_MODE_APPEND) {
        foreach my $cart (@carts) {
            my @items = $cart->items->all;
            foreach my $item (@items) {
                $self->add($item);
            };
        };
    } else {
        throw Handel::Exception::Argument(-text =>
            translate('UNKNOWN_RESTORE_MODE')
        );
    };

    return;
};

sub save {
    my $self = shift;
    $self->type(CART_TYPE_SAVED);

    return;
};

sub subtotal {
    my $self     = shift;
    my $storage  = $self->result->storage;
    my $items    = $self->items;
    my $subtotal = 0.00;

    while (my $item = $items->next) {
        $subtotal += ($item->total);
    };

    return $storage->currency_class->new($subtotal);
};

1;
__END__

=head1 NAME

Handel::Cart - Module for maintaining shopping cart contents

=head1 SYNOPSIS

    use Handel::Cart;
    
    my $cart = Handel::Cart->create({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });
    
    $cart->add({
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });
    
    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };
    $item->subtotal;

=head1 DESCRIPTION

Handel::Cart is component for maintaining simple shopping cart data.

=head1 CONSTRUCTOR

=head2 create

=over

=item Arguments: \%data [, \%options]

=back

Creates a new shopping cart object containing the specified data.

    my $cart = Handel::Cart->create({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        name    => 'My Shopping Cart'
    });

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

The following options are available:

=over

=item storage

A storage object to use to create a new cart object. Currently, this storage
object B<must> have the same columns as the default storage object for the
current cart class.

=back

=head1 METHODS

=head2 add

=over

=item Arguments: \%data | $item

=back

Adds a new item to the current shopping cart and returns an instance of the
item class specified in cart object storage. You can either pass the item
data as a hash reference:

    my $item = $cart->add({
        shopper  => '10020400-E260-11CF-AE68-00AA004A34D5',
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

or pass an existing cart item:

    my $wishlist = Handel::Cart->search({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        type    => CART_TYPE_SAVED
    })->first;
    
    $cart->add(
        $wishlist->items({sku => 'ABC-123'})->first
    );

When passing an existing cart item to add, all columns in the source item will
be copied into the destination item if the column exists in both the
destination and source, and the column isn't the primary key or the foreign
key of the item relationship.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter isn't a hashref or an object that subclasses
Handel::Cart::Item.

=head2 clear

Deletes all items from the current cart.

    $cart->clear;

=head2 count

Returns the number of items in the cart object.

    my $numitems = $cart->count;

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes the item matching the supplied filter from the current cart.

    $cart->delete({
        sku => 'ABC-123'
    });

=head2 destroy

=over

=item Arguments: \%filter

=back

Deletes entire shopping carts (and their items) from the database. When called
as an object method, this will delete all items from the current cart object
and deletes the cart object itself. C<filter> will be ignored.

    $cart->destroy;

When called as a class method, this will delete all carts matching C<filter>.

    Handel::Cart->destroy({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception will be
thrown if C<filter> is not a HASH reference.

=head2 items

=over

=item Arguments: \%filter [, \%options]

=back

Loads the current carts items matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of items in
list context.

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };
    
    my @items = $cart->items;

By default, the items returned as Handel::Cart::Item objects. To return
something different, set C<item_class> in the local C<storage> object.

The following options are available:

=over

=item order_by

Order the items by the column(s) and order specified. This option uses the SQL
style syntax:

    my $items = $cart->items(undef, {order_by => 'sku ASC'});

=back

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if parameter one isn't a hashref or undef.

=head2 search

=over

=item Arguments: \%filter [, \%options]

=back

Loads existing carts matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of carts in
list context.

    my $iterator = Handel::Cart->search({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type    => CART_TYPE_SAVED
    });
    
    while (my $cart = $iterator->next) {
        print $cart->id;
    };
    
    my @carts = Handel::Cart->search();

The following options are available:

=over

=item storage

A storage object to use to load cart objects. Currently, this storage
object B<must> have the same columns as the default storage object for the
current cart class.

=item order_by

Order the items by the column(s) and order specified. This option uses the SQL
style syntax:

    my $carts = Handel::Cart->search(undef, {order_by => 'name ASC'});

=back

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

=head2 save

Marks the current shopping cart type as C<CART_TYPE_SAVED>.

    $cart->save

=head2 restore

=over

=item Arguments: \%filter [, $mode]

=item Arguments: $cart [, $mode]

=back

Copies (restores) items from a cart, or a set of carts back into the current
shopping cart. You may either pass in a hash reference containing the search
criteria of the shopping cart(s) to restore:

    $cart->restore({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type    => CART_TYPE_SAVED
    });

or you can pass in an existing C<Handel::Cart> object or subclass.

    my $wishlist = Handel::Cart->search({
        id   => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type => CART_TYPE_SAVED
    })->first;
    
    $cart->restore($wishlist);

For either method, you may also specify the mode in which the cart should be
restored. The following modes are available:

=over

=item C<CART_MODE_REPLACE>

All items in the current cart will be deleted before the saved cart is restored
into it. This is the default if no mode is specified.

=item C<CART_MODE_MERGE>

If an item with the same SKU exists in both the current cart and the saved cart,
the quantity of each will be added together and applied to the same sku in the
current cart. Any price differences are ignored and we assume that the price in
the current cart has the more up to date price.

=item C<CART_MODE_APPEND>

All items in the saved cart will be appended to the list of items in the current
cart. No effort will be made to merge items with the same SKU and duplicates
will be ignored.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter isn't a hashref or a C<Handel::Cart::Item> object
or subclass.

=back

=head1 COLUMNS

The following methods are mapped to columns in the default cart schema. These
methods may or may not be available in any subclasses, or in situations where
a custom schema is being used that has different column names.

=head2 id

Returns the id of the current cart.

    print $cart->id;

See L<Handel::Schema::Cart/id> for more information about this column.

=head2 shopper

=over

=item Arguments: $shopper

=back

Gets/sets the id of the shopper the cart should be associated with.

    $cart->shopper('11111111-1111-1111-1111-111111111111');
    print $cart->shopper;

See L<Handel::Schema::Cart/shopper> for more information about this column.

=head2 type

=over

=item Arguments: $type

=back

Gets/sets the type of the current cart. Currently the two types allowed are:

=over

=item C<CART_TYPE_TEMP>

The cart is temporary and may be purged during any [external] cleanup process
after the designated amount of inactivity.

=item C<CART_TYPE_SAVED>

The cart should be left untouched by any cleanup process and is available to the
shopper at any time.

=back

    $cart->type(CART_TYPE_SAVED);
    print $cart->type;

See L<Handel::Schema::Cart/type> for more information about this column.

=head2 name

=over

=item Arguments: $name

=back

Gets/sets the name of the current cart.

    $cart->name('My Naw Cart');
    print $cart->name;

See L<Handel::Schema::Cart/name> for more information about this column.

=head2 description

=over

=item Arguments: $description

=back

Gets/sets the description of the current cart.

    $cart->description('New Cart');
    print $cart->description;

See L<Handel::Schema::Cart/description> for more information about this column.

=head2 subtotal

Returns the current total price of all the items in the cart object as a
stringified L<Handel::Currency|Handel::Currency> object. This is equivalent to:

    my $iterator = $cart->items;
    my $subtotal = 0;
    while (my $item = $iterator->next) {
        $subtotal += $item->quantity*$item->price;
    };

=head1 SEE ALSO

L<Handel::Cart::Item>, L<Handel::Schema::Cart>, L<Handel::Constants>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
