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

use constant RETURNAS_AUTO     => 0;
use constant RETURNAS_ITERATOR => 1;
use constant RETURNAS_LIST     => 2;
use constant RETURNAS_ARRAY    => 2;

@EXPORT_OK = qw(CART_MODE_APPEND
                CART_MODE_MERGE
                CART_MODE_REPLACE
                CART_TYPE_SAVED
                CART_TYPE_TEMP
                RETURNAS_AUTO
                RETURNAS_ITERATOR
                RETURNAS_LIST
                RETURNAS_ARRAY
);

%EXPORT_TAGS =
    (   all  => \@EXPORT_OK,
        cart => [ qw(CART_MODE_APPEND
                     CART_MODE_MERGE
                     CART_MODE_REPLACE
                     CART_TYPE_SAVED
                     CART_TYPE_TEMP
        )],
        returnas => [ qw(RETURNAS_AUTO
                        RETURNAS_ITERATOR
                        RETURNAS_LIST
                        RETURNAS_ARRAY
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

All items in the saved cart will be appended to the list of items in the current
cart. No effort will be made to merge items with the same SKU and duplicates
will be ignored.

=head2 C<CART_MODE_MERGE>

If an item with the same SKU exists in both the current cart and the saved cart,
the quantity of each will be added together and applied to the same sku in the
current cart. Any price differences are ignored and we assume that the price in
the current cart is more up to date.

=head2 C<CART_MODE_REPLACE>

All items in the current cart will be deleted before the saved cart is restored
into it. This is the default if no mode is specified.

=head2 C<CART_TYPE_SAVED>

Marks the cart as permanent. Carts with this value set should never be
automatically reaped from the database during cleanup.

=head2 C<CART_TYPE_TEMP>

Any cart with this type could be purged form the database during cleanup at any
time.

=head2 C<RETURNAS_AUTO>

When calling C<load> or C<items> on C<Handel::Cart>, it will attempt to return
the most appropriate object. In list context, it will return a list. In
scalar context, it will return a C<Handel::Iterator> object. If the iterator
only contains one item, that item will be returns instead.

=head2 C<RETURNAS_ITERATOR>

Always return a C<Handel::Iterator> object regardless of context or the amount
of retults.

=head2 C<RETURNAS_LIST>

Always return a list regardless of context or the amount of results.

=head2 C<RETURNAS_ARRAY>

Same as C<RETURNAS_LIST>

=head1 EXPORT_TAGS

The following C<%EXPORT_TAGS> are defined for C<Handel::Constants>. See
L<Exporter> for further details on using export tags.

=head2 C<:all>

This exports all constants found in this module.

=head2 C<:cart>

This exports all C<CART_*> constants in this module.

=head2 C<:returnas>

This exports all C<RETURNAS_*> constants in this module.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/



