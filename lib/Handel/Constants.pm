package Handel::Constants;
use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS);

BEGIN {
    use base 'Exporter';
};

use constant CART_MODE_APPEND  => 3;
use constant CART_MODE_MERGE   => 2;
use constant CART_MODE_REPLACE => 1;

use constant CART_TYPE_TEMP    => 0;
use constant CART_TYPE_SAVED   => 1;

@EXPORT_OK = qw(CART_MODE_APPEND
                CART_MODE_MERGE
                CART_MODE_REPLACE
                CART_TYPE_SAVED
                CART_TYPE_TEMP
);

%EXPORT_TAGS =
    (   all  => \@EXPORT_OK,
        cart => [ qw(CART_MODE_APPEND
                     CART_MODE_MERGE
                     CART_MODE_REPLACE
                     CART_TYPE_SAVED
                      CART_TYPE_TEMP
        )]
    );

1;
__END__

=head1 NAME

Handel::Constants - Common constants used in Handel

=head1 VERSION

    $Id$

=head1 SYNOPSIS

    use Handel::Constants qw(:cart);

    my $cart = Handel::Cart->new({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

    if ($cart->type == CART_TYPE_SAVED) {
        print 'This cart is saved!';
    };

=head1 DESCRIPTION

C<Handel::Constants> contains a set of constants used throughout C<Handel>. It
may be useful (or even a good idea) to use these in your code. :-)

By default, C<Handel::Constants> export C<nothing>. Use can use the export tags
below to export all or only certain groups of constants.

=head1 CONSTANTS

=head2 C<CART_MODE_APPEND>

=head2 C<CART_MODE_MERGE>

=head2 C<CART_MODE_REPLACE>

=head2 C<CART_TYPE_SAVED>

=head2 C<CART_TYPE_TEMP>

=head1 EXPORT_TAGS

The following C<%EXPORT_TAGS> are defined for C<Handel::Constants>. See
L<Exporter> for further details on using export tags.

=head2 C<:all>

This exports all constants found in this module.

=head2 C<:cart>

This exports all C<CART_*> constants in this module.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/



