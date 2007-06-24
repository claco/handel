# $Id$
package Handel::Subclassing::OrderItem;
use strict;
use warnings;
use base qw/Handel::Order::Item/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
