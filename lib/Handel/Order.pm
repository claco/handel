# $Id$
package Handel::Order;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw/:checkout :order/;
    use Handel::Constraints qw/:all/;
    use Handel::Currency;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed/;
    use Carp qw/carp/;

    use base qw/Handel::Base/;
    __PACKAGE__->item_class('Handel::Order::Item');
    __PACKAGE__->cart_class('Handel::Cart');
    __PACKAGE__->checkout_class('Handel::Checkout');
    __PACKAGE__->storage_class('Handel::Storage::DBIC::Order');
    __PACKAGE__->mk_group_accessors('inherited', qw/ccn cctype ccm ccy ccvn ccname ccissuenumber ccstartdate ccenddate/);
    __PACKAGE__->create_accessors;
};

sub create { ## no critic (ProhibitExcessComplexity)
    my ($self, $data, $opts) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    no strict 'refs';
    my $storage = $opts->{'storage'};
    if (!$storage) {
        $storage = $self->storage;
    };

    my $process = $opts->{'process'} || 0;
    my $cart = delete $data->{'cart'};

    if (defined $cart) {
        throw Handel::Exception::Argument( -details =>
          translate('CARTPARAM_NOT_HASH_CART')
        ) if (
                (ref($cart) && !blessed($cart) && ref($cart) ne 'HASH') ||
                (blessed($cart) && !$cart->isa('Handel::Cart'))
        ); ## no critic

        if (ref $cart eq 'HASH') {
            $cart = $self->cart_class->search($cart)->first;

            throw Handel::Exception::Order( -details =>
                translate('CART_NOT_FOUND')
            ) unless $cart; ## no critic
        } elsif (!blessed($cart)) {
            my ($primary_key) = $self->cart_class->storage->primary_columns;

            $cart = $self->cart_class->search({$primary_key => $cart})->first;

            throw Handel::Exception::Order( -details =>
                translate('CART_NOT_FOUND')
            ) unless $cart; ## no critic
        };

        throw Handel::Exception::Order( -details =>
            translate('ORDER_CREATE_FAILED_CART_EMPTY')
        ) unless $cart->count > 0; ## no critic
    };

    if (defined $cart) {
        if ($cart->storage->has_column('shopper') && !defined $data->{'shopper'}) {
            $data->{'shopper'} = $cart->shopper;
        };
    };

    my $order = $self->create_instance(
        $storage->create($data)
    );

    if (defined $cart) {
        $self->copy_cart($order, $cart);
        $self->copy_cart_items($order, $cart);
    };

    if ($process) {
        my $checkout = $self->checkout_class->new;
        $checkout->order($order);

        my $status = $checkout->process([CHECKOUT_PHASE_INITIALIZE]);
        if ($status == CHECKOUT_STATUS_OK) {
            $checkout->order->update;
        } else {
            $order->destroy;
            undef $order;
        };
        undef $checkout;
    };

    return $order;
};

sub copy_cart {
    my ($self, $order, $cart) = @_;

    $order->subtotal($cart->subtotal);
    $order->update;

    return;
};

sub copy_cart_items {
    my ($self, $order, $cart) = @_;

    foreach my $item ($cart->items) {
        $order->add($item);
    };

    return;
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate('PARAM1_NOT_HASH_CARTITEM_ORDERITEM')
    ) unless (ref($data) eq 'HASH' || $data->isa('Handel::Order::Item') || $data->isa('Handel::Cart::Item')); ## no critic

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
    my $self  = shift;

    return $self->result->count_items;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless ref($filter) eq 'HASH'; ## no critic

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

sub save {
    my $self = shift;
    $self->type(ORDER_TYPE_SAVED);

    return;
};

sub reconcile {
    my ($self, $cart) = @_;

    throw Handel::Exception::Argument( -details =>
      translate('CARTPARAM_NOT_HASH_CART')
    ) if ( ## no critic
            (ref($cart) && !blessed($cart) && ref($cart) ne 'HASH') ||
            (blessed($cart) && !$cart->isa('Handel::Cart'))
    );

    if (ref $cart eq 'HASH') {
        $cart = $self->cart_class->search($cart)->first;

        throw Handel::Exception::Order( -details =>
            translate('CART_NOT_FOUND')
        ) unless $cart; ## no critic
    } elsif (!blessed($cart)) {
        my ($primary_key) = $self->cart_class->storage->primary_columns;

        $cart = $self->cart_class->search({$primary_key => $cart})->first;

        throw Handel::Exception::Order( -details =>
            translate('CART_NOT_FOUND')
        ) unless $cart; ## no critic
    };

    throw Handel::Exception::Order( -details =>
        translate('ORDER_CREATE_FAILED_CART_EMPTY')
    ) unless $cart->count > 0; ## no critic

    if ($self->subtotal != $cart->subtotal || $self->count != $cart->count) {
        $self->clear;
        $self->copy_cart($self, $cart);
        $self->copy_cart_items($self, $cart);
    };

    return;
};

1;
__END__

=head1 NAME

Handel::Order - Module for maintaining order contents

=head1 SYNOPSIS

    use Handel::Order;
    
    my $order = Handel::Order->create({
        id => '12345678-9098-7654-322-345678909876'
    });
    
    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };

=head1 DESCRIPTION

Handel::Order is a component for maintaining simple order records.

=head1 CONSTRUCTOR

=head2 create

=over

=item Arguments: \%data [, \%options]

=back

Creates a new order object containing the specified data.

If the cart key is passed, a new order record will be created from the specified
carts contents. The cart key can be a cart primary key value, a cart object,
or a hash reference contain the search criteria to load matching carts.

By default, new will use Handel::Cart to load the specified cart, unless you
have set C<cart_class> to use another class.

    my $order = Handel::Order->create({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => $cartobject
    });
    
    my $order = Handel::Order->create({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => '11112222-3333-4444-5555-666677778888'
    });
    
    my $order = Handel::Order->create({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => {
            id => '11112222-3333-4444-5555-666677778888',
            type => CART_TYPE_TEMP
        }
    });

The following options are available:

=over

=item process

When true, the newly created order will be run through the
C<CHECKOUT_PHASE_INITIALIZE> process before it is returned.

=item storage

A storage object to use to create a new order object. Currently, this storage
object B<must> have the same columns as the default storage object for the
current order class.

=back

=head1 METHODS

=head2 add

=over

=item Arguments: \%data | $item

=back

Adds a new item to the current order and returns an instance of the item class
specified in order object storage. You can either pass the item data as a hash
reference:

    my $item = $cart->add({
        shopper  => '10020400-E260-11CF-AE68-00AA004A34D5',
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

or pass an existing item:

    $order->add(
        $cart->items->first
    );

When passing an existing cart/order item to add, all columns in the source item
will be copied into the destination item if the column exists in both the
destination and source, and the column isn't the primary key or the foreign
key of the item relationship.

A C<Handel::Exception::Argument> exception is thrown if the first parameter
isn't a hashref or an object that subclasses Handel::Cart::Item.

=head2 cart_class

=over

=item Arguments: $order_class

=back

Gets/sets the name of the class to use when loading existing cart into the
new order. By default, it loads carts using Handel::Cart. While you can set this
directly in your application, it's best to set it in a custom subclass of
Handel::Order.

    package CustomOrder;
    use strict;
    use warnings;
    use base qw/Handel::Order/;
    __PACKAGE__->cart_class('CustomCart');

=head2 checkout_class

=over

=item Arguments: $checkout_class

=back

Gets/sets the name of the checkout class to use when processing the new order
through the INITIALIZE phase if the C<process> flag is on. By default, it uses
Handel::Checkout. While you can set this directly in your application, it's best
to set it in a custom subclass of Handel::Order.

    package CustomOrder;
    use strict;
    use warnings;
    use base qw/Handel::Order/;
    __PACKAGE__->checkout_class('CustomCheckout');

=head2 clear

Deletes all items from the current order.

    $cart->clear;

=head2 count

Returns the number of items in the order object.

    my $numitems = $order->count;

=head2 copy_cart

=over

=item Arguments: $order, $cart

=back

When creating a new order from an existing cart, C<copy_cart> will be called to
copy the carts contents into the new order object. If you are using custom cart
or order subclasses, the default copy_cart will only copy the fields declared in
Handel::Cart, ignoring any custom fields you may add.

To fix this, simply subclass Handel::Order and override C<copy_cart>. As its
parameters, it will receive the order and cart objects.

    package CustomOrder;
    use strict;
    use warnings;
    use base qw/Handel::Order/;
    
    sub copy_cart {
        my ($self, $order, $cart) = @_;
    
        # copy stock fields
        $self->SUPER::copy_cart($order, $cart);

        # now catch the custom ones
        $order->customfield($cart->customfield);
    };

=head2 copy_cart_items

=over

=item Arguments: $order, $cart

=back

When creating a new order from an existing cart, C<copy_cart_items> will be
called to copy the cart items into the new order object. If you are using
custom cart or order subclasses, the default C<copy_cart_item> will only copy
the fields that in both the cart item and the order item schemas.

To fix this, simply subclass Handel::Order and override C<copy_cart>. As its
parameters, it will receive the order and cart objects.

    package CustomOrder;
    use strict;
    use warnings;
    use base qw/Handel::Order/;
    
    __PACKAGE__->cart_class('CustomCart');
    
    sub copy_cart_items {
        my ($self, $order, $cart) = @_;
        my $items = $cart->items(undef, RETURNAS_ITERATOR);
    
        while (my $item = $items->next) {
            my %copy;
    
            foreach (CustomCart::Item->columns) {
                next if $_ =~ /^(id|cart)$/i;
                $copy{$_} = $item->$_;
            };
    
            $copy{'id'} = $self->uuid unless constraint_uuid($copy{'id'});
            $copy{'orderid'} = $order->id;
            $copy{'total'} = $copy{'quantity'}*$copy{'price'};
    
            $order->add_to__items(\%copy);
        };
    };

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes the item matching the supplied filter from the current order.

    $order->delete({
        sku => 'ABC-123'
    });

=head2 destroy

=over

=item Arguments: \%filter

=back

Deletes entire orders (and their items) from the database. When called
as an object method, this will delete all items from the current order object
and deletes the order object itself. C<filter> will be ignored.

    $order->destroy;

When called as a class method, this will delete all orders matching C<filter>.

    Handel::Order->destroy({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception will be
thrown if C<filter> is not a HASH reference.

=head2 items

=over

=item Arguments: \%filter [, \%options]

=back

Loads the current orders items matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of items in
list context.

    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };
    
    my @items = $order->items;

By default, the items returned as Handel::Order::Item objects. To return
something different, set C<item_class> in the local C<storage> object.

The following options are available:

=over

=item order_by

Order the items by the column(s) and order specified. This option uses the SQL
style syntax:

    my $items = $order->items(undef, {order_by => 'sku ASC'});

=back

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if parameter one isn't a hashref or undef.

=head2 search

=over

=item Arguments: \%filter [, \%options]

=back

Loads existing orders matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of orders in
list context.

    my $iterator = Handel::Order->search({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type    => ORDER_TYPE_SAVED
    });
    
    while (my $order = $iterator->next) {
        print $order->id;
    };
    
    my @orders = Handel::Orders->search();

The following options are available:

=over

=item storage

A storage object to use to load order objects. Currently, this storage
object B<must> have the same columns as the default storage object for the
current order class.

=item order_by

Order the items by the column(s) and order specified. This option uses the SQL
style syntax:

    my $orders = Handel::Order->search(undef, {order_by => 'updated DESC'});

=back

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

=head2 save

Marks the current order type as C<ORDER_TYPE_SAVED>.

    $order->save

=head2 reconcile

=over

=item Arguments: $cart_id | $cart | \%filter

=back

This method copies the specified carts items into the order only if the item
count or the subtotal differ.

The cart key can be a cart id (uuid), a cart object, or a hash reference
contain the search criteria to load matching carts.

    $order->reconcile('11111111-1111-1111-1111-111111111111');
    $order->reconcile({name => 'My Cart'});
    
    my $cart = Handel::Cart->search({
        id => '11111111-1111-1111-1111-111111111111'
    })->first;
    $order->reconcile($cart);

By default, new will use Handel::Cart to load the specified cart, unless you
have set C<cart_class>on in the local <storage> object to use another class.

=head1 COLUMNS

The following methods are mapped to columns in the default order schema. These
methods may or may not be available in any subclasses, or in situations where
a custom schema is being used that has different column names.

=head2 id

Returns the id of the current order.

    print $order->id;

See L<Handel::Schema::Order/id> for more information about this column.

=head2 shopper

=over

=item Arguments: $shopper

=back

Gets/sets the id of the shopper the order should be associated with.

    $order->shopper('11111111-1111-1111-1111-111111111111');
    print $order->shopper;

See L<Handel::Schema::Order/shopper> for more information about this column.

=head2 type

=over

=item Arguments: $type

=back

Gets/sets the type of the current order. Currently the two types allowed are:

=over

=item C<ORDER_TYPE_TEMP>

The order is temporary and may be purged during any [external] cleanup process
after the designated amount of inactivity.

=item C<ORDER_TYPE_SAVED>

The order should be left untouched by any cleanup process and is available to
the shopper at any time.

=back

    $order->type(ORDER_TYPE_SAVED);
    print $order->type;

See L<Handel::Schema::Order/type> for more information about this column.

=head2 number

=over

=item Arguments: $number

=back

Gets/sets the order number.

    $order->number(1015275);
    print $order->number;

See L<Handel::Schema::Order/number> for more information about this column.

=head2 created

=over

=item $datetime

=back

Gets/sets the date/time when the order was created. The date is returned as a
stringified L<DateTime|DateTime> object.

    $order->created('2006-04-11T12:34:65');
    print $order->created;

See L<Handel::Schema::Order/created> for more information about this column.

=head2 updated

=over

=item $datetime

=back

Gets/sets the date/time when the order was last updated. The date is returned
as a stringified L<DateTime|DateTime> object.

    $order->updated('2006-04-11T12:34:65');
    print $order->updated;

See L<Handel::Schema::Order/updated> for more information about this column.

=head2 comments

=over

=item $comments

=back

Gets/sets the comments for this order.

    $order->comments('Handel with care');
    print $order->comments;

See L<Handel::Schema::Order/comments> for more information about this column.

=head2 shipmethod

=over

=item $shipmethod

=back

Gets/sets the shipping method for this order.

    $order->shipmethod('UPS 2nd Day');
    print $order->shipmethod;

See L<Handel::Schema::Order/shipmethod> for more information about this column.

=head2 shipping

=over

=item Arguments: $price

=back

Gets/sets the shipping cost for the order item. The price is returned as a
stringified L<Handel::Currency|Handel::Currency> object.

    $item->shipping(12.95);
    print $item->shipping;
    print $item->shipping->format;

See L<Handel::Schema::Order/shipping> for more information about this column.

=head2 handling

=over

=item Arguments: $price

=back

Gets/sets the handling cost for the order item. The price is returned as a
stringified L<Handel::Currency|Handel::Currency> object.

    $item->handling(12.95);
    print $item->handling;
    print $item->handling->format;

See L<Handel::Schema::Order/handling> for more information about this column.

=head2 tax

=over

=item Arguments: $price

=back

Gets/sets the tax for the order item. The price is returned as a
stringified L<Handel::Currency|Handel::Currency> object.

    $item->tax(12.95);
    print $item->tax;
    print $item->tax->format;

See L<Handel::Schema::Order/tax> for more information about this column.

=head2 subtotal

=over

=item Arguments: $price

=back

Gets/sets the subtotal for the order item. The price is returned as a
stringified L<Handel::Currency|Handel::Currency> object.

    $item->subtotal(12.95);
    print $item->subtotal;
    print $item->subtotal->format;

See L<Handel::Schema::Order/subtotal> for more information about this column.

=head2 total

=over

=item Arguments: $price

=back

Gets/sets the total for the order item. The price is returned as a
stringified L<Handel::Currency|Handel::Currency> object.

    $item->total(12.95);
    print $item->total;
    print $item->total->format;

See L<Handel::Schema::Order/total> for more information about this column.

=head2 billtofirstname

=over

=item Arguments: $firstname

=back

Gets/sets the bill to first name.

    $order->billtofirstname('Chistopher');
    print $order->billtofirstname;

See L<Handel::Schema::Order/billtofirstname> for more information about this
column.

=head2 billtolastname

=over

=item Arguments: $lastname

=back

Gets/sets the bill to last name

    $order->billtolastname('Chistopher');
    print $order->billtolastname;

See L<Handel::Schema::Order/billtolastname> for more information about this
column.

=head2 billtoaddress1

=over

=item Arguments: $address1

=back

Gets/sets the bill to address line 1

    $order->billtoaddress1('1234 Main Street');
    print $order->billtoaddress1;

See L<Handel::Schema::Order/billtoaddress1> for more information about this
column.

=head2 billtoaddress2

=over

=item Arguments: $address2

=back

Gets/sets the bill to address line 2

    $order->billtoaddress2('Suite 34b');
    print $order->billtoaddress2;

See L<Handel::Schema::Order/billtoaddress2> for more information about this
column.


=head2 billtoaddress3

=over

=item Arguments: $address3

=back

Gets/sets the bill to address line 3

    $order->billtoaddress3('Floor 5');
    print $order->billtoaddress3;

See L<Handel::Schema::Order/billtoaddress3> for more information about this
column.

=head2 billtocity

=over

=item Arguments: $city

=back

Gets/sets the bill to city

    $order->billtocity('Smallville');
    print $order->billtocity;

See L<Handel::Schema::Order/billtocity> for more information about this
column.

=head2 billtostate

=over

=item Arguments: $state

=back

Gets/sets the bill to state/province

    $order->billtostate('OH');
    print $order->billtostate;

See L<Handel::Schema::Order/billtostate> for more information about this
column.

=head2 billtozip

=over

=item Arguments: $zip

=back

Gets/sets the bill to zip/postal code

    $order->billtozip('12345-6500');
    print $order->billtozip;

See L<Handel::Schema::Order/billtozip> for more information about this
column.

=head2 billtocountry

=over

=item Arguments: $country

=back

Gets/sets the bill to country

    $order->billtocountry('US');
    print $order->billtocountry;

See L<Handel::Schema::Order/billtocountry> for more information about this
column.

=head2 billtodayphone

=over

=item Arguments: $phone

=back

Gets/sets the bill to day phone number

    $order->billtodayphone('800-867-5309');
    print $order->billtodayphone;

See L<Handel::Schema::Order/billtodayphone> for more information about this
column.

=head2 billtonightphone

=over

=item Arguments: $phone

=back

Gets/sets the bill to night phone number

    $order->billtonightphone('800-867-5309');
    print $order->billtonightphone;

See L<Handel::Schema::Order/billtonightphone> for more information about this
column.

=head2 billtofax

=over

=item Arguments: $fax

=back

Gets/sets the bill to fax number

    $order->billtofax('888-132-4335');
    print $order->billtofax;

See L<Handel::Schema::Order/billtofax> for more information about this
column.

=head2 billtoemail

=over

=item Arguments: $email

=back

Gets/sets the bill to email address

    $order->billtoemail('claco@chrislaco.com');
    print $order->billtoemail;

See L<Handel::Schema::Order/billtoemail> for more information about this
column.

=head2 shiptosameasbillto

=over

=item Arguments: 0|1

=back

When true, the ship address is the same as the bill to address.

    $order->shiptosameasbillto(1);
    print $order->shiptosameasbillto;

See L<Handel::Schema::Order/shiptosameasbillto> for more information about this
column.

=head2 shiptofirstname

=over

=item Arguments: $firstname

=back

Gets/sets the ship to first name.

    $order->shiptofirstname('Chistopher');
    print $order->shiptofirstname;

See L<Handel::Schema::Order/shiptofirstname> for more information about this
column.

=head2 shiptolastname

=over

=item Arguments: $lastname

=back

Gets/sets the ship to last name

    $order->shiptolastname('Chistopher');
    print $order->shiptolastname;

See L<Handel::Schema::Order/shiptolastname> for more information about this
column.

=head2 shiptoaddress1

=over

=item Arguments: $address1

=back

Gets/sets the ship to address line 1

    $order->shiptoaddress1('1234 Main Street');
    print $order->shiptoaddress1;

See L<Handel::Schema::Order/shiptoaddress1> for more information about this
column.

=head2 shiptoaddress2

=over

=item Arguments: $address2

=back

Gets/sets the ship to address line 2

    $order->shiptoaddress2('Suite 34b');
    print $order->shiptoaddress2;

See L<Handel::Schema::Order/shiptoaddress2> for more information about this
column.


=head2 shiptoaddress3

=over

=item Arguments: $address3

=back

Gets/sets the ship to address line 3

    $order->shiptoaddress3('Floor 5');
    print $order->shiptoaddress3;

See L<Handel::Schema::Order/shiptoaddress3> for more information about this
column.

=head2 shiptocity

=over

=item Arguments: $city

=back

Gets/sets the ship to city

    $order->shiptocity('Smallville');
    print $order->shiptocity;

See L<Handel::Schema::Order/shiptocity> for more information about this
column.

=head2 shiptostate

=over

=item Arguments: $state

=back

Gets/sets the ship to state/province

    $order->shiptostate('OH');
    print $order->shiptostate;

See L<Handel::Schema::Order/shiptostate> for more information about this
column.

=head2 shiptozip

=over

=item Arguments: $zip

=back

Gets/sets the ship to zip/postal code

    $order->shiptozip('12345-6500');
    print $order->shiptozip;

See L<Handel::Schema::Order/shiptozip> for more information about this
column.

=head2 shiptocountry

=over

=item Arguments: $country

=back

Gets/sets the ship to country

    $order->shiptocountry('US');
    print $order->shiptocountry;

See L<Handel::Schema::Order/shiptocountry> for more information about this
column.

=head2 shiptodayphone

=over

=item Arguments: $phone

=back

Gets/sets the ship to day phone number

    $order->shiptodayphone('800-867-5309');
    print $order->shiptodayphone;

See L<Handel::Schema::Order/shiptodayphone> for more information about this
column.

=head2 shiptonightphone

=over

=item Arguments: $phone

=back

Gets/sets the ship to night phone number

    $order->shiptonightphone('800-867-5309');
    print $order->shiptonightphone;

See L<Handel::Schema::Order/shiptonightphone> for more information about this
column.

=head2 shiptofax

=over

=item Arguments: $fax

=back

Gets/sets the ship to fax number

    $order->shiptofax('888-132-4335');
    print $order->shiptofax;

See L<Handel::Schema::Order/shiptofax> for more information about this
column.

=head2 shiptoemail

=over

=item Arguments: $email

=back

Gets/sets the ship to email address

    $order->shiptoemail('claco@chrislaco.com');
    print $order->shiptoemail;

See L<Handel::Schema::Order/shiptoemail> for more information about this
column.

=head1 TEMPORARY COLUMNS

The following columns are really just methods to hold sensitive 
order data that we don't want to actually store in the database.

=head2 ccn

=over

=item Arguments: $ccn

=back

Gets/sets the credit cart number.

    $order->ccn(4444333322221111);
    print $order->ccn;

=head2 cctype

=over

=item Arguments: $type

=back

Gets/sets the credit cart type.

    $order->cctype('MasterCard');
    print $order->cctype;

=head2 ccm

=over

=item Arguments: $month

=back

Gets/sets the credit cart expiration month.

    $order->ccm(1);
    print $order->ccm;

=head2 ccy

=over

=item Arguments: $year

=back

Gets/sets the credit cart expiration year.

    $order->ccyear(2010);
    print $order->ccyear;

=head2 ccvn

=over

=item Arguments: $cvvn

=back

Gets/sets the credit cart verification number.

    $order->cvvn(102);
    print $order->cvvn;

=head2 ccname

=over

=item Arguments: $name

=back

Gets/sets the credit cart holders name as it appears on the card.

    $order->ccname('CHRISTOPHER H. LACO');
    print $order->ccname;

=head2 ccissuenumber

=over

=item Arguments: $number

=back

Gets/sets the credit cart issue number.

    $order->ccissuenumber(16544);
    print $order->ccissuenumber;

=head2 ccstartdate

=over

=item Arguments: $startdate

=back

Gets/sets the credit cart start date.

    $order->ccstartdate('1/2/2009');
    print $order->ccstartdate;

=head2 ccenddate

=over

=item Arguments: $enddate

=back

Gets/sets the credit cart end date.

    $order->ccenddate('12/31/2011');
    print $order->ccenddate;

=head1 SEE ALSO

L<Handel::Order::Item>, L<Handel::Schema::Order>, L<Handel::Constants>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
