package Handel::Constraints;
use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS);

BEGIN {
    use base 'Exporter';
    use Handel::Constants qw(:cart);
};

@EXPORT_OK = qw(&constraint_quantity
                &constraint_price
                &constraint_uuid
                &constraint_cart_type
);

%EXPORT_TAGS = (all => \@EXPORT_OK);

sub constraint_quantity {
    my $value = shift;

    return ($value =~ /^\d+$/ && $value > 0);
};

sub constraint_price {
    my $value = shift;

    return ($value =~ /^\d{1,5}(\.\d{1,2})?$/ && $value > 0);
};

sub constraint_uuid {
    my $value = shift;

    return ($value =~ m/  ^[0-9a-f]{8}-
                           [0-9a-f]{4}-
                           [0-9a-f]{4}-
                           [0-9a-f]{4}-
                           [0-9a-f]{12}$
                      /ix);
};

sub constraint_cart_type {
    my $value    = shift;

    return if $value !~ /[0-9]/;

    if ($value != CART_TYPE_SAVED && $value != CART_TYPE_TEMP) {
        return 0;
    };
    return 1;
};

1;
__END__

=head1 NAME

Handel::Constraints - Common database constraints used to validate input data

=head1 VERSION

    $Id$

=head1 SYNOPSIS

    use Handel::Constraints qw(constraint_quantity);

    my $qty = 'bogus-1';

    if (constraint_quantity($qty) {
        print 'invalid quantity';
    };

=head1 DESCRIPTION

C<Handel::Constraints> contains a set of functions used to validate data
submitted by users into Handel objects. By default, C<Handel::Constraints>
doesn't export anything. Use the export tags to export groups of functions, or
specify the exact methods you are interested in using. See L<Exporter> for more
information on using export tags.

=head1 FUNCTIONS

=head2 C<constraint_quantity>

Returns 1 if the value passed is a numeric, non-negative value, otherwise
 it returns C<undef>.

=head2 C<constraint_price>

Returns 1 if the value passed is a numeric, non-negative value between 0 and
99999.99, otherwise it returns C<undef>.

=head2 C<constraint_uuid>

Returns 1 if the value passed is conforms to the GUID/UUID format, otherwise it
returns C<undef>. Currently, this does B<not> expect the brackets around the
value.

    constraint_uuid( '11111111-1111-1111-1111-111111111111' ); # 1

    constraint_uuid('{11111111-1111-1111-1111-111111111111}'); # undef

This will probably change in the future, or some sort of stripping of the
brackets may occur.

=head2 C<constraint_cart_type>

Returns 1 if the value passed is C<CART_TYPE_SAVED> or C<CART_TYPE_TEMP>,
otherwise it returns C<undef>.

=head1 EXPORT_TAGS

=head2 C<:all>

Exports all functions into the classes namespace.

    use Handel::Constraints qw(:all);

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/










