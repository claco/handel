# $Id$
package Handel::Subclassing::CartItem;
use strict;
use warnings;
use base 'Handel::Cart::Item';

__PACKAGE__->add_columns('custom');

1;
