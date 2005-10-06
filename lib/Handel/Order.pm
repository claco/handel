# $Id$
package Handel::Order;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Cart;
    use Handel::Checkout;
    use Handel::Constants qw(:checkout :returnas :order);
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->table('orders');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id shopper type number created updated comments
    shipmethod shipping handling tax subtotal total
    billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3
    billtocity billtostate billtozip billtocountry  billtodayphone
    billtonightphone billtofax billtoemail shiptosameasbillto
    shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3
    shiptocity shiptostate shiptozip shiptocountry shiptodayphone
    shiptonightphone shiptofax shiptoemail)
);
__PACKAGE__->columns(
    TEMP => qw(ccn cctype ccm ccy ccvn ccname)
);

__PACKAGE__->has_many(_items => 'Handel::Order::Item', 'orderid');
__PACKAGE__->has_a(subtotal  => 'Handel::Currency');
__PACKAGE__->has_a(total     => 'Handel::Currency');
__PACKAGE__->has_a(shipping  => 'Handel::Currency');
__PACKAGE__->has_a(handling  => 'Handel::Currency');
__PACKAGE__->has_a(tax       => 'Handel::Currency');

__PACKAGE__->add_constraint('id',       id       => \&constraint_uuid);
__PACKAGE__->add_constraint('shopper',  shopper  => \&constraint_uuid);
__PACKAGE__->add_constraint('type',     type     => \&constraint_order_type);
__PACKAGE__->add_constraint('shipping', shipping => \&constraint_price);
__PACKAGE__->add_constraint('handling', handling => \&constraint_price);
__PACKAGE__->add_constraint('subtotal', subtotal => \&constraint_price);
__PACKAGE__->add_constraint('tax',      tax      => \&constraint_price);
__PACKAGE__->add_constraint('total',    total    => \&constraint_price);

sub new {
    my ($self, $data, $process) = @_;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    if (!defined($data->{'type'})) {
        $data->{'type'} = ORDER_TYPE_TEMP;
    };

    my $cart = $data->{'cart'};
    my $is_uuid = constraint_uuid($cart);
    delete $data->{'cart'};

    if (defined $cart) {
        throw Handel::Exception::Argument( -details =>
          translate(
              'Cart reference is not a HASH reference or Handel::Cart') . '.') unless
                  (ref($cart) eq 'HASH' or UNIVERSAL::isa($cart, 'Handel::Cart') or $is_uuid);

        if (ref $cart eq 'HASH') {
            $cart = Handel::Cart->load($cart, RETURNAS_ITERATOR)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        } elsif ($is_uuid) {
            $cart = Handel::Cart->load({id => $cart}, RETURNAS_ITERATOR)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        };

        throw Handel::Exception::Order( -details =>
            translate(
                'Could not create a new order because the supplied cart is empty') . '.') unless
                    $cart->count > 0;
    };

    my $order = $self->insert($data);

    if (defined $cart) {
        my $subtotal = 0;
        my $items = $cart->items(undef, RETURNAS_ITERATOR);
        if ($cart->shopper && !$order->shopper) {
            $order->shopper($cart->shopper);
        };
        while (my $item = $items->next) {
            my %copy;

            foreach ($item->columns) {
                next if $_ =~ /^(id|cart)$/i;
                $copy{$_} = $item->$_;
            };

            $copy{'id'} = $self->uuid unless constraint_uuid($copy{'id'});
            $copy{'orderid'} = $order->id;
            $copy{'total'} = $copy{'quantity'}*$copy{'price'};
            $subtotal += $copy{'total'};

            $order->add_to__items(\%copy);
        };

        $order->subtotal($subtotal);
        $order->update;
    };

    if ($process) {
        my $checkout = Handel::Checkout->new;
        $checkout->order($order);

        my $status = $checkout->process([CHECKOUT_PHASE_INITIALIZE]);
        if ($status == CHECKOUT_STATUS_OK) {
            $checkout->order->update;
        } else {
            $order->SUPER::delete;
            undef $order;
        };
        undef $checkout;
    };

    return $order;
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference, Handel::Cart::Item or Handel::Order::Item') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Order::Item') or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
            $data->{'id'} = $self->uuid;
        };

        return $self->add_to__items($data);
    } else {
        my %copy;

        foreach ($data->columns) {
            next if $_ =~ /^(id|orderid|cart)$/i;
            $copy{$_} = $data->$_;
        };
        if (UNIVERSAL::isa($data, 'Handel::Cart::Item')) {
            $copy{'total'} = $data->total;
        };

        $copy{'id'} = $self->uuid;

        return $self->add_to__items(\%copy);
    };
};

sub clear {
    my $self = shift;

    $self->_items->delete_all;

    return undef;
};

sub count {
    my $self  = shift;

    return $self->_items->count || 0;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($filter) eq 'HASH';

    ## I'd much rather use $self->_items->search_like, but it doesn't work that
    ## way yet. This should be fine as long as :weaken refs works.
    return Handel::Order::Item->search_like(%{$filter},
        orderid => $self->id)->delete_all;
};

sub item_class {
    my ($class, $item_class) = @_;

    if (Class::DBI->VERSION < 3.000008) {
        undef(*_items);
        undef(*add_to__items);
        __PACKAGE__->has_many(_items => $item_class, 'orderid');
    } else {
        $class->has_many(_items => $item_class, 'orderid');
    };
};

sub items {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $wantiterator ||= RETURNAS_AUTO;
    $filter       ||= {};

    my $wildcard = Handel::DBI::has_wildcard($filter);

    ## If the filter as a wildcard, push it through a fresh search_like since it
    ## doesn't appear to be available within a loaded object.
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @items = $wildcard ?
            Handel::Order::Item->search_like(%{$filter}, orderid => $self->id) :
            $self->_items(%{$filter});

        return @items;
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $wildcard ?
            Handel::Order::Item->search_like(%{$filter}, orderid => $self->id) :
            $self->_items(%{$filter});

        return $iterator;
    } else {
        my $iterator = $wildcard ?
            Handel::Order::Item->search_like(%{$filter}, orderid => $self->id) :
            $self->_items(%{$filter});
        if ($iterator->count == 1 && $wantiterator != RETURNAS_ITERATOR && $wantiterator != RETURNAS_LIST) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub load {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $wantiterator ||= RETURNAS_AUTO;

    ## only return array if wantarray and not explicitly asking for an iterator
    ## or we've explicitly asked for a list/array
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @orders = $filter ? $self->search_like(%{$filter}) :
            $self->retrieve_all;
        return @orders;
    ## return an iterator if explicitly asked for
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $filter ?
            $self->search_like(%{$filter}) : $self->retrieve_all;

        return $iterator;
    ## full out auto
    } else {
        my $iterator = $filter ?
            $self->search_like(%{$filter}) : $self->retrieve_all;

        if ($iterator->count == 1 && $wantiterator != RETURNAS_ITERATOR && $wantiterator != RETURNAS_LIST) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub reconcile {
    my ($self, $cart) = @_;

    my $is_uuid = constraint_uuid($cart);

    if (defined $cart) {
        throw Handel::Exception::Argument( -details =>
          translate(
              'Cart reference is not a HASH reference or Handel::Cart') . '.') unless
                  (ref($cart) eq 'HASH' or UNIVERSAL::isa($cart, 'Handel::Cart') or $is_uuid);

        if (ref $cart eq 'HASH') {
            $cart = Handel::Cart->load($cart, RETURNAS_ITERATOR)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        } elsif ($is_uuid) {
            $cart = Handel::Cart->load({id => $cart}, RETURNAS_ITERATOR)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        };

        throw Handel::Exception::Order( -details =>
            translate(
                'Could not create a new order because the supplied cart is empty') . '.') unless
                    $cart->count > 0;
    };

    if ($self->subtotal != $cart->subtotal || $self->count != $cart->count) {
        $self->clear;
        my @citems = $cart->items;
        foreach my $item (@citems) {
            $self->add($item);
        };
        $self->subtotal($cart->subtotal);
    };
};

1;
__END__

=head1 NAME

Handel::Order - Module for maintaining order contents

=head1 SYNOPSIS

    my $order = Handel::Order->new({
        id => '12345678-9098-7654-322-345678909876'
    });

    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };

=head1 DESCRIPTION

C<Handel::Order> is a component for maintaining simple order records.

While C<Handel::Order> subclasses L<Class::DBI>, it is strongly recommended that
you not use its methods unless it's absolutely necessary. Stick to the
documented methods here and you'll be safe should I decide to implement some
other data access mechanism. :-)

=head1 CONSTRUCTOR

There are three ways to create a new order object. You can either pass a hashref
into C<new> containing all the required values needed to create a new order
record or pass a hashref into C<load> containing the search criteria to use
to load an existing order or set of orders.

B<BREAKING API CHANGE:> Starting in version 0.17_04, new no longer automatically
creates a checkout process for C<CHECKOUT_PHASE_INITIALIZE>. The C<$noprocess>
parameter has been renamed to C<$process>. The have the new order automatically
run a checkout process, set $process to 1.

B<NOTE:> Starting in version 0.17_02, the cart is no longer required! You can
create an order record that isn't associated with a current cart.

B<NOTE:> As of version 0.17_02, Order::subtotal and Order::Item:: total are
calculated once B<only> when creating an order from an existing cart. After that
order is created, any changes to items price/wuantity/totals and the orders subtotals
must be calculated manually and put into the database by the user though their methods.

If the cart key is passed, a new order record will be created from the specified
carts contents. The cart key can be a cart id (uuid), a cart object, or a has reference
contain the search criteria to load matching carts.

=over

=item C<Handel::Order-E<gt>new(\%data [, $process])>

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => $cartobject
    });

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => '11112222-3333-4444-5555-666677778888'
    });

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => {
            id => '11112222-3333-4444-5555-666677778888',
            type => CART_TYPE_TEMP
        }
    });

=item C<Handel::Order-E<gt>load([\%filter, $wantiterator])>

    my $order = Handel::Order->load({
        id => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

You can also omit \%filter to load all available orders.

    my @orders = Handel::Order->load();

In scalar context C<load> returns a C<Handel::Order> object if there is a single
result, or a L<Handel::Iterator> object if there are multiple results. You can
force C<load> to always return an iterator even if only one cart exists by
setting the C<$wantiterator> parameter to C<RETURNAS_ITERATOR>.

    my $iterator = Handel::Order->load(undef, RETURNAS_ITERATOR);
    while (my $item = $iterator->next) {
        print $item->sku;
    };

See L<Handel::Constants> for the available C<RETURNAS> options.

A C<Handel::Exception::Argument> exception is thrown if the first parameter is
not a hashref.

=back

=head1 METHODS

=head2 add(\%data)

You can add items to the order by supplying a hashref containing the
required name/values or by passing in a newly create Handel::Order::Item
object. If successful, C<add> will return a L<Handel::Order::Item> object
reference.

Yes, I know. Why a hashref and not just a hash? So I can add new params
later if need be. Oh yeah, and "Because I Can". :-P

=over

=item C<$cart-E<gt>add(\%data)>

    my $item = $cart->add({
        shopper  => '10020400-E260-11CF-AE68-00AA004A34D5',
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

=item C<$cart-E<gt>add($object)>

    my $item = Handel::Cart::Item->new({
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });
    ...
    $cart->add($item);

A C<Handel::Exception::Argument> exception is thrown if the first parameter
isn't a hashref or a C<Handel::Cart::Item> object.

=back

=head2 clear

This method removes all items from the current cart object.

    $cart->clear;

=head2 delete(\%filter)

This method deletes the cart item(s) matching the supplied filter values and
returns the number of items deleted.

    if ( $cart->delete({id => '8D4B0BE1-C02E-11D2-A33D-00A0C94B8D0E'}) ) {
        print 'Item deleted';
    };

=head2 item_class($classname)

Sets the name of the class to be used when returning or creating order items.
While you can set this directly in your application, it's best to set it
in a custom subclass of Handel::Order.

    package CustomOrder;
    use strict;
    use warnings;
    use base 'Handel::Order';

    __PACKAGE__->item_class('CustomOrder::CustomItem';

    1;

=head2 items([\%filter, [$wantiterator])

You can retrieve all or some of the items contained in the order via the C<items>
method. In a scalar context, items returns an iterator object which can be used
to cycle through items one at a time. In list context, it will return an array
containing all items.

    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };

    my @items = $order->items;
    ...
    dosomething(\@items);

When filtering the items in the order in scalar context, a
C<Handel::Order::Item> object will be returned if there is only one result. If
there are multiple results, a Handel::Iterator object will be returned
instead. You can force C<items> to always return a C<Handel::Iterator> object
even if only one item exists by setting the $wantiterator parameter to
C<RETURNAS_ITERATOR>.

    my $item = $order->items({sku => 'SKU1234'}, RETURNAS_ITERATOR);
    if ($item->isa('Handel::Order::Item)) {
        print $item->sku;
    } else {
        while ($item->next) {
            print $_->sku;
        };
    };

See the C<RETURNAS> constants in L<Handel::Constants> for other options.

In list context, filtered items return an array of items just as when items is
called without a filter specified.

    my @items - $order->items((sku -> 'SKU1%'});

A C<Handel::Exception::Argument> exception is thrown if parameter one isn't a
hashref or undef.

=head2 reconcile($cart)

This method copies the specified carts items into the order only if the item
count or the subtotal differ.

The cart key can be a cart id (uuid), a cart object, or a hash reference
contain the search criteria to load matching carts.

=head2 billtofirstname

Gets/sets the bill to first name

=head2 billtolastname

Gets/sets the bill to last name

=head2 billtoaddress1

Gets/sets the bill to address line 1

=head2 billtoaddress2

Gets/sets the bill to address line 2

=head2 billtoaddress3

Gets/sets the bill to address line 3

=head2 billtocity

Gets/sets the bill to city

=head2 billtostate

Gets/sets the bill to state/province

=head2 billtozip

Gets/sets the bill to zip/postal code

=head2 billtocountry

Gets/sets the bill to country

=head2 billtodayphone

Gets/sets the bill to day phone number

=head2 billtonightphone

Gets/sets the bill to night phone number

=head2 billtofax

Gets/sets the bill to fax number

=head2 billtoemail

Gets/sets the bill to email address

=head2 comments

Gets/sets the comments for this order

=head2 count

Gets the number of items in the order

=head2 created

Gets/sets the created date of the order

=head2 handling

Gets/sets the handling charge

=head2 id

Gets/sets the record id

=head2 number

Gets/sets the order number

=head2 shipmethod

Gets/sets the shipping method

=head2 shipping

Gets/sets the shipping cost

=head2 shiptosameasbillto

Gets/sets the ship to same as bill to flag. When set, the ship to information
will be copied from the bill to

=head2 shiptofirstname

Gets/sets the ship to first name

=head2 shiptolastname

Gets/sets the ship to last name

=head2 shiptoaddress1

Gets/sets the ship to address line 1

=head2 shiptoaddress2

Gets/sets the ship to address line 2

=head2 shiptoaddress3

Gets/sets the ship to address line 3

=head2 shiptocity

Gets/sets the ship to city

=head2 shiptostate

Gets/sets the ship to state

=head2 shiptozip

Gets/sets the ship to zip/postal code

=head2 shiptocountry

Gets/sets the ship to country

=head2 shiptodayphone

Gets/sets the ship to day phone number

=head2 shiptonightphone

Gets/sets the ship to night phone number

=head2 shiptofax

Gets/sets the ship to fax number

=head2 shiptoemail

Gets/sets the ship to email address

=head2 shopper

Gets/sets the shopper id

=head2 subtotal

Gets/sets the orders subtotal

=head2 tax

Gets/sets the orders tax

=head2 total

Gets/sets the orders total

=head2 type

Gets/sets the order type

=head2 updated

Gets/sets the last updated date of the order

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
