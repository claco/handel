# $Id$
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->cart_class('Handel::Subclassing::OrdersCart');

1;
