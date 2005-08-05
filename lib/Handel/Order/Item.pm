# $Id$
package Handel::Order::Item;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);
};

__PACKAGE__->table('order_items');
__PACKAGE__->autoupdate(1);
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id orderid sku quantity price description total));
__PACKAGE__->columns(Essential => qw(id orderid sku quantity price description total));
__PACKAGE__->has_a(price => 'Handel::Currency');
__PACKAGE__->has_a(total => 'Handel::Currency');
__PACKAGE__->add_constraint('quantity', quantity => \&constraint_quantity);
__PACKAGE__->add_constraint('price',    price    => \&constraint_price);
__PACKAGE__->add_constraint('id',       id       => \&constraint_uuid);
__PACKAGE__->add_constraint('orderid',  orderid  => \&constraint_uuid);
__PACKAGE__->add_constraint('total',    total    => \&constraint_price);

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    return $self->construct($data);
};

1;
__END__

=head1 NAME

Handel::Order::Item - Module representing an indivudal order line item

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

=head1 CONSTRUCTOR

=head2 new

You can create a new C<Handel::Order::Item> object by calling the C<new> method:

    my $item = Handel::Order::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1,
        total => 1.23
    });

    $item->quantity(2);

    print $item->total;

This is a lazy operation. No actual item record is created until the item object
is passed into the C<add> method of a C<Handel::Order> object.

=head1 METHOS

=head2 description

Gets/sets the item description

=head2 id

Gets/sets the item id

=head2 price

Gets/sets the item price

=head2 quantity

Gets/sets the item quantity

=head2 sku

Gets/sets the item sku

=head2 total

Gets/sets the item total

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
