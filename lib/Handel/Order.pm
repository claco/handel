# $Id$
package Handel::Order;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constants qw(:checkout :returnas :order);
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);
};

__PACKAGE__->autoupdate(0);
__PACKAGE__->table('order');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id shopper type number created updated comments
    shipmethod shipping handling tax subtotal total
    billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3
    billtocity billtostate billtozip billtocountry  billtodayphone
    billtonightphone billtofax billtoemail shiptosameasbillto
    shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3
    shiptocity shiptostate shiptozip shiptocountry shiptodayphone
    shiptonightphone shiptofax shiptoemail));

__PACKAGE__->has_many(_items => 'Handel::Order::Item', 'order');
__PACKAGE__->has_a(subtotal => 'Handel::Currency');
__PACKAGE__->has_a(total => 'Handel::Currency');
__PACKAGE__->has_a(shipping => 'Handel::Currency');
__PACKAGE__->has_a(handling => 'Handel::Currency');
__PACKAGE__->has_a(tax => 'Handel::Currency');

__PACKAGE__->add_constraint('id',       id       => \&constraint_uuid);
__PACKAGE__->add_constraint('shopper',  shopper  => \&constraint_uuid);
__PACKAGE__->add_constraint('type',     type     => \&constraint_cart_type);
__PACKAGE__->add_constraint('shipping', shipping => \&constraint_price );
__PACKAGE__->add_constraint('handling', handling => \&constraint_price );
__PACKAGE__->add_constraint('subtotal', subtotal => \&constraint_price );
__PACKAGE__->add_constraint('tax',      tax      => \&constraint_price );
__PACKAGE__->add_constraint('total',    total    => \&constraint_price );

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference or Handel::Cart') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Cart'));

    if (ref $data eq 'HASH') {
        $data = Handel::Cart->load($data, RETURNAS_ITERATOR)->first;

        throw Handel::Exception::Order( -details =>
            translate(
                'Could not find a cart matching the supplid search criteria') . '.') unless $data;
    };

    throw Handel::Exception::Order( -details =>
        translate(
            'Could not create a new order because the supplied cart is empty') . '.') unless
                $data->count > 0;

    my $order = $self->create({type => ORDER_TYPE_TEMP});

    while (my $item = $data->items->next) {
        my %copy = %{$data};

        $copy{'id'} = $self->uuid;

        $order->add_to__items(\%copy);
    };

    my $checkout = Handel::Checkout->new();

    $checkout->process($order, CHECKOUT_PHASE_INITIALIZE);

    if ($checkout->status == CHECKOUT_STATUS_OK) {
        $checkout->order->update;
    } else {
        $order->delete;
    };

    return $order;
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

Handel::Order - Module to manipulate order records

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

You may also pass an already existing Handel::Cart object into C<new> instead
of a hash of search critera.

=over

=item C<Handel::Order-E<gt>new(\%data)>
=item C<Handel::Order-E<gt>new(Handel::Cart)>

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777'
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

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
