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
__PACKAGE__->add_constraint('quantity', quantity => \&constraint_quantity);
__PACKAGE__->add_constraint('price',    price    => \&constraint_price);
__PACKAGE__->add_constraint('id',       id       => \&constraint_uuid);
__PACKAGE__->add_constraint('cart',     cart     => \&constraint_uuid);
__PACKAGE__->add_constraint('subtotal', subtotal => \&constraint_price);
__PACKAGE__->add_constraint('total',    total    => \&constraint_price);

1;
__END__