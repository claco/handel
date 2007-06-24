# $Id$
package Handel::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Base/;
    use Handel::L10N qw/translate/;

    __PACKAGE__->storage_class('Handel::Storage::DBIC::Cart::Item');
    __PACKAGE__->create_accessors;
};

sub create {
    my ($self, $data, $opts) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    no strict 'refs';
    my $storage = $opts->{'storage'};
    if (!$storage) {
        $storage = $self->storage;
    };

    return $self->create_instance(
        $storage->create($data)
    );
};

sub total {
    my $self = shift;
    my $storage = $self->result->storage;

    return $storage->currency_class->new($self->quantity * $self->price);
};

1;
__END__

=head1 NAME

Handel::Cart::Item - Module representing an individual shopping cart item

=head1 SYNOPSIS

    use Handel::Cart::Item;
    
    my $item = Handel::Cart::Item->create({
        cart     => '11111111-1111-1111-1111-111111111111',
        sku      => '1234',
        price    => 1.23,
        quantity => 1
    });

=head1 DESCRIPTION

Handel::Cart::Item is used in two main ways. First, you can create or edit cart
items individually:

    use Handel::Cart::Item;
    
    my $item = Handel::Cart::Item->create({
        cart => '11111111-1111-1111-1111-111111111111',
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

As a general rule, you probably want to add/edit items using the cart objects
C<items> and C<add> methods below instead.

Second, the C<items> method of any valid Handel::Cart object returns a
collection of Handel::Cart::Item objects:

    my @items = $cart->items;
    foreach (@items) {
        print $_->sku;
    };

=head1 CONSTRUCTOR

=head2 create

=over

=item Arguments: \%data [, \%options]

=back

You can create a new Handel::Cart::Item object by calling the C<new> method:

    my $item = Handel::Cart::Item->create({
        cart => '11111111-1111-1111-1111-111111111111',
        sku => '1234',
        price => 1.23,
        quantity => 1
    });
    
    $item->quantity(2);
    
    print $item->total;

The following options are available:

=over

=item storage

A storage object to use to create a new item object. Currently, this storage
object B<must> have the same columns as the default storage object for the
current item class.

=back

=head1 COLUMNS

The following methods are mapped to columns in the default cart schema.
These methods may or may not be available in any subclasses, or in situations
where a custom schema is being used that has different column names.

=head2 id

Returns the id of the current cart item.

    print $item->id;

See L<Handel::Schema::Cart::Item/id> for more information about this column.

=head2 cart

Gets/sets the id of the cart this item belongs to.

    $item->cart('11111111-1111-1111-1111-111111111111');
    print $item->cart;

See L<Handel::Schema::Cart::Item/cart> for more information about this column.

=head2 sku

=over

=item Arguments: $sku

=back

Gets/sets the sku (stock keeping unit/part number) for the cart item.

    $item->sku('ABC123');
    print $item->sku;

See L<Handel::Schema::Cart::Item/sku> for more information about this column.

=head2 quantity

=over

=item Arguments: $quantity

=back

Gets/sets the quantity, or the number of this item being purchased.

    $item->quantity(3);
    print $item->quantity;

By default, the value supplied will be checked against
L<Handel::Constraints/constraint_quantity> to verify it is within the valid
range of values.

See L<Handel::Schema::Cart::Item/quantity> for more information about this
column.

=head2 price

=over

=item Arguments: $price

=back

Gets/sets the price for the cart item. The price is returned as a stringified
L<Handel::Currency|Handel::Currency> object.

    $item->price(12.95);
    print $item->price;
    print $item->price->format;


See L<Handel::Schema::Cart::Item/price> for more information about this column.

=head2 total

Returns the total price for the cart item as a stringified
L<Handel::Currency|Handel::Currency> object. This is really just
quantity*total and is provided for convenience.

    print $item->total;
    print $item->total->format;

=head2 description

=over

=item Arguments: $description

=back

Gets/sets the description for the current cart item.

    $item->description('Best Item Ever');
    print $item->description;

See L<Handel::Schema::Cart::Item/description> for more information about this
column.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Schema::Cart::Item>, L<Handel::Currency>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
