# $Id$
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base 'Handel::Checkout';

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
