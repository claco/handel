# $Id$
package Handel::Subclassing::OrderOnly;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->add_columns('custom');

1;
