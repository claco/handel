# $Id: Constraints.pm 4 2004-12-28 03:01:15Z claco $
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

Handel::Constraints - Database I/O Constraints

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item C<constraint_quantity($)>

=item C<constraint_price($)>

=item C<constraint_uuid($)>

=item C<constraint_cart_type(%)>

=back

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
