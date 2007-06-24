# $Id$
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
