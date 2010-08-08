# $Id$
package Handel::Constraints;
use strict;
use warnings;
use vars qw/@EXPORT_OK %EXPORT_TAGS/;

BEGIN {
    use base 'Exporter';
    use Handel;
    use Handel::Constants qw/:cart :checkout :order/;
    use Handel::Exception;
    use Handel::L10N qw/translate/;
    use Locale::Currency;
    use Scalar::Util qw/blessed/;
    use Config;
};

@EXPORT_OK = qw/&constraint_quantity
                &constraint_price
                &constraint_uuid
                &constraint_cart_type
                &constraint_cart_name
                &constraint_currency_code
                &constraint_checkout_phase
                &constraint_order_type
/;

%EXPORT_TAGS = (all => \@EXPORT_OK);

my %codes;

sub constraint_quantity {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    my $cfg    = Handel->config;
    my $max    = $cfg->{'HandelMaxQuantity'};
    my $action = lc $cfg->{'HandelMaxQuantityAction'};

    if ($action eq 'exception' && $max) {
        throw Handel::Exception::Constraint( -details =>
            translate('QUANTITY_GT_MAX', $value, $max)
        ) if $value > $max; ## no critic
    } elsif ($action eq 'adjust' && $max) {
        if (ref($object) && $value && $value > $max) {
            $changing->{'quantity'} = $max;
        };
    };

    return ($value =~ /^\d+$/ && $value > 0);
};

sub constraint_price {
    my $value = defined $_[0] ? shift : '';

    if (blessed $value && $value->isa('Data::Currency')) {
        $value = $value->value;
    };

    if ($Config{'uselongdouble'}) {
        return ($value =~ /^\d{1,5}(\.\d{1,17})?$/);        
    } else {
        return ($value =~ /^\d{1,5}(\.\d{1,2})?$/);
    };
};

sub constraint_uuid {
    my $value = defined $_[0] ? shift : '';

    return ($value =~ m{  ^[0-9a-f]{8}-
                           [0-9a-f]{4}-
                           [0-9a-f]{4}-
                           [0-9a-f]{4}-
                           [0-9a-f]{12}$
                      }ix);
};

sub constraint_cart_type {
    my $value = defined $_[0] ? shift : '';

    return if $value !~ /[0-9]/;

    if ($value != CART_TYPE_SAVED && $value != CART_TYPE_TEMP) {
        return 0;
    };
    return 1;
};

sub constraint_cart_name {
    my ($value, $object, $column, $changing) = @_;
    my $type = ref $changing ? $changing->{'type'} : '';

    if (constraint_cart_type($type) && $type == CART_TYPE_SAVED && !length($value || '')) {
        return 0;
    };
    return 1;
};


sub constraint_currency_code {
    my $value = defined $_[0] ? uc(shift) : '';

    return unless ($value =~ /^[A-Z]{3}$/); ## no critic

    if (! keys %codes) {
        %codes = map {uc($_) => uc($_)} all_currency_codes();
    };
    return exists $codes{$value};
};

sub constraint_checkout_phase {
    my $value = defined $_[0] ? shift : '';

    return if $value !~ /[0-9]/;

    foreach my $const (@{Handel::Constants->CHECKOUT_ALL_PHASES}) {
        if ($value == $const) {
            return 1;
        };
    };

    return 0;
};

sub constraint_order_type {
    my $value = defined $_[0] ? shift : '';

    return if $value !~ /[0-9]/;

    if ($value != ORDER_TYPE_SAVED && $value != ORDER_TYPE_TEMP) {
        return 0;
    };
    return 1;
};

1;
__END__

=head1 NAME

Handel::Constraints - Common database constraints used to validate input data

=head1 SYNOPSIS

    use Handel::Constraints qw/constraint_quantity/;
    
    my $qty = 'bogus-1';
    
    if (constraint_quantity($qty)) {
        print 'invalid quantity';
    };

=head1 DESCRIPTION

Handel::Constraints contains a set of functions used to validate data submitted
by users into Handel objects. By default, Handel::Constraints doesn't export
anything. Use the export tags to export groups of functions, or specify the
exact methods you are interested in using. See L<Exporter|Exporter> for more
information on using export tags.

=head1 FUNCTIONS

=head2 constraint_quantity

=over

=item Arguments: $quantity

=back

Returns 1 if the value passed is a numeric, non-negative value that is less
than or equal HandelMaxQuantity. Otherwise it returns C<undef>.

See L<Handel::ConfigReader|Handel::ConfigReader> for more information on
HandelMaxQuantity and HandelMaxQuantityAction.

=head2 constraint_price

=over

=item Arguments: $price

=back

Returns 1 if the value passed is a numeric, non-negative value between 0 and
99999.99, otherwise it returns C<undef>.

=head2 constraint_uuid

=over

=item Arguments: $string

=back

Returns 1 if the value passed is conforms to the GUID/UUID format, otherwise it
returns C<undef>. Currently, this does B<not> expect the brackets around the
value.

    constraint_uuid( '11111111-1111-1111-1111-111111111111' ); # 1
    
    constraint_uuid('{11111111-1111-1111-1111-111111111111}'); # undef

This will probably change in the future, or some sort of stripping of the
brackets may occur.

=head2 constraint_cart_type

=over

=item Arguments: $type

=back

Returns 1 if the value passed is C<CART_TYPE_SAVED> or C<CART_TYPE_TEMP>,
otherwise it returns C<undef>.

=head2 constraint_currency_code

=over

=item Arguments: $code

=back

Returns 1 if the value passed is considered a 3 letter currency code.
If L<Locale::Currency|Locale::Currency> is installed, it will verify the 3
letter code is actually a valid currency code.

If Locale::Currency is not installed, it simply checks that the code conforms
to:

    /^[A-Z]{3}$/

=head2 constraint_checkout_phase

=over

=item Arguments: $phase

=back

Returns 1 if the value passed is one of the C<CHECKOUT_PHASE_*> constants,
otherwise it returns C<undef>.

=head2 constraint_order_type

=over

=item Arguments: $type

=back

Returns 1 if the value passed is C<ORDER_TYPE_SAVED> or C<ORDER_TYPE_TEMP>,
otherwise it returns C<undef>.

=head2 constraint_cart_name

=over

=item Arguments: $name

=back

Returns 0 if the cart type is C<CART_TYPE_SAVED> and the name is undefined,
otherwise it returns 1.

=head1 EXPORT_TAGS

=head2 :all

Exports all functions into the callers namespace.

    use Handel::Constraints qw/:all/;

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
