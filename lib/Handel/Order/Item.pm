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
__PACKAGE__->columns(All => qw(id order sku quantity price description total));
__PACKAGE__->columns(Essential => qw(id order sku quantity price description total));
__PACKAGE__->has_a(price => 'Handel::Currency');
__PACKAGE__->has_a(total => 'Handel::Currency');
__PACKAGE__->add_constraint('quantity', quantity => \&constraint_quantity);
__PACKAGE__->add_constraint('price',    price    => \&constraint_price);
__PACKAGE__->add_constraint('id',       id       => \&constraint_uuid);
__PACKAGE__->add_constraint('order',    order    => \&constraint_uuid);
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

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
