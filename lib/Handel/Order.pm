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
        $data = Handel::Cart->load([\%filter, RETURNAS_ITERATOR)->first;

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

        %copy{'id'} = $self->uuid;

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

1;
__END__