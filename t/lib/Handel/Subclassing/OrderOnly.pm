# $Id$
package Handel::Subclassing::OrderOnly;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
