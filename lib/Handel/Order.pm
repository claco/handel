# $Id$
package Handel::Order;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Checkout;
    use Handel::Constants qw(:checkout :returnas :order);
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);
};

__PACKAGE__->autoupdate(0);
__PACKAGE__->table('orders');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id shopper type number created updated comments
    shipmethod shipping handling tax subtotal total
    billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3
    billtocity billtostate billtozip billtocountry  billtodayphone
    billtonightphone billtofax billtoemail shiptosameasbillto
    shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3
    shiptocity shiptostate shiptozip shiptocountry shiptodayphone
    shiptonightphone shiptofax shiptoemail));

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
    my ($self, $data, $noprocess) = @_;

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

    my $order = $self->create($data);
    my $subtotal = 0;
    my $items = $cart->items(undef, RETURNAS_ITERATOR);
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

    unless ($noprocess) {
        my $checkout = Handel::Checkout->new;
        $checkout->order($order);

        my $status = $checkout->process([CHECKOUT_PHASE_INITIALIZE]);
        if ($status == CHECKOUT_STATUS_OK) {
            $checkout->order->update;
        } else {
            $order->delete;
            undef $order;
        };
        undef $checkout;
    };

    return $order;
};

sub count {
    my $self  = shift;

    return $self->_items->count || 0;
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

B<NOTE:> The only required hash key is C<cart>. C<new> will copy the specified
carts items inthe the order items. C<cart> can be an already existing
Handel::Cart object, of a hash reference of search critera, or a cart id (uuid).

=over

=item C<Handel::Order-E<gt>new(\%data)>

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

See L<Handel::Contstants> for the available C<RETURNAS> options.

A C<Handel::Exception::Argument> exception is thrown if the first parameter is
not a hashref.

=back

=head1 METHODS

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

=head2 count

Returns the number of items in the order object.

    my $numitems = $order->count;

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
