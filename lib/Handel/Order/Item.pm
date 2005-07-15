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
__PACKAGE__->autoupdate(0);
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
