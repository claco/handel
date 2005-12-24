# $Id$
package Handel::Subclassing::Checkout;
use strict;
use warnings;
use base 'Handel::Checkout';

__PACKAGE__->order_class('Handel::Subclassing::Order');

1;
