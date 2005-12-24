# $Id$
package Handel::Subclassing::OrderItem;
use strict;
use warnings;
use base 'Handel::Order::Item';

__PACKAGE__->add_columns('custom');

1;
