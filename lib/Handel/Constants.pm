# $Id: Constants.pm 4 2004-12-28 03:01:15Z claco $
package Handel::Constants;
use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS);

BEGIN {
    use base 'Exporter';
};

use constant CART_TYPE_TEMP    => 0;
use constant CART_TYPE_SAVED   => 1;
use constant CART_MODE_REPLACE => 1;
use constant CART_MODE_MERGE   => 2;
use constant CART_MODE_APPEND  => 3;

@EXPORT_OK = qw(CART_TYPE_TEMP
                CART_TYPE_SAVED
                CART_MODE_REPLACE
                CART_MODE_MERGE
                CART_MODE_APPEND
);

%EXPORT_TAGS =
    (   all  => \@EXPORT_OK,
        cart => [ qw(CART_TYPE_TEMP
                     CART_TYPE_SAVED
                     CART_MODE_REPLACE
                     CART_MODE_MERGE
                     CART_MODE_APPEND
        )]
    );

1;
__END__

=head1 NAME

Handel::Constants - Constants

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
