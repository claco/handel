# $Id$
package Handel::Subclassing::CartOnly;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->add_columns('custom');

1;