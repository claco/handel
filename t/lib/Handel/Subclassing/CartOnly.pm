# $Id$
package Handel::Subclassing::CartOnly;
use strict;
use warnings;
use base qw/Handel::Cart/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
