# $Id$
package Handel::Subclassing::Order;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->item_class('Handel::Subclassing::OrderItem');
__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
