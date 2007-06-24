# $Id$
package Handel::Subclassing::Cart;
use strict;
use warnings;
use base qw/Handel::Cart/;

__PACKAGE__->item_class('Handel::Subclassing::CartItem');
__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
