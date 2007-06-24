# $Id$
package Handel::Test::Schema;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Schema/;
    use Handel::Schema::DBIC::Cart;
    use Handel::Schema::DBIC::Cart::Item;
    use Handel::Schema::DBIC::Order;
    use Handel::Schema::DBIC::Order::Item;
};

## All 4 classes aren't usually loaded together so we'll do this to avoid both
## sources named 'Items'
__PACKAGE__->register_class('Carts', 'Handel::Schema::DBIC::Cart');
__PACKAGE__->register_class('CartItems', 'Handel::Schema::DBIC::Cart::Item');
__PACKAGE__->register_class('Orders', 'Handel::Schema::DBIC::Order');
__PACKAGE__->register_class('OrderItems', 'Handel::Schema::DBIC::Order::Item');

sub dsn {
    return shift->storage->connect_info->[0];
};

1;
