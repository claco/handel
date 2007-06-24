# $Id$
package Handel::Currency;
use strict;
use warnings;

BEGIN {
    use base qw/Data::Currency/;
    use Handel ();
    use Handel::Exception ();
    use Handel::L10N qw/translate/;
    use Handel::Constraints qw/constraint_currency_code/;
    use Class::Inspector ();
};

sub code {
    my ($self, $code) = @_;
    my $cfg = Handel->config;

    if ($code) {
        throw Handel::Exception::Argument(
            -details => translate('CURRENCY_CODE_INVALID', $code)
        ) unless constraint_currency_code($code); ## no critic

        $self->SUPER::code($code);
    };

    $code = $self->get_simple('code') || $cfg->{'HandelCurrencyCode'};

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $code)
    ) unless constraint_currency_code($code); ## no critic

    return $code;
};

sub convert {
    my ($self, $to) = @_;
    my $from = $self->code;

    $to ||= '';

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $from)
    ) unless constraint_currency_code($from); ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $to)
    ) unless constraint_currency_code($to); ## no critic

    return $self->SUPER::convert($to);
};

sub format {
    my ($self, $format) = @_;
    my $cfg = Handel->config;

    if ($format) {
        $self->SUPER::format($format);
    };

    $format = $self->get_simple('format') || $cfg->{'HandelCurrencyFormat'};

    return $format ? $format : undef;
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "use $value"; ## no critic

            throw Handel::Exception(
                -details => translate('COMPCLASS_NOT_LOADED', $field, $value)
            ) if $@; ## no critic
        };
    };

    $self->set_inherited($field, $value);

    return;
};

1;
__END__

=head1 NAME

Handel::Currency - Price container to do currency conversion/formatting

=head1 SYNOPSIS

    use Handel::Currency;
    
    my $price = Handel::Currency->new(1.2. 'USD');
    print $price;            # 1.20 USD
    print $price+1           # 2.2
    print $price->code;      # USD
    print $price->format;    # FMT_SYMBOL
    print $price->as_string; # 1.20 USD
    print $price->as_string('FMT_SYMBOL'); # $1.20
    
    print 'Your price in Canadian Dollars is: ';
    print $price->convert('CAD')->value;

=head1 DESCRIPTION

The Handel::Currency module provides basic currency formatting within Handel
using L<Data::Currency|Data::Currency>. It can be used separately to format any
number into a more friendly formatted currency string.

    my $price = 1.23;
    my $currency = Handel::Currency->new($price);

    print $currency->as_string;

A new Handel::Currency object is automatically returned within the shopping
cart when calling C<subtotal>, C<total>, and C<price> as an lvalue:

    my $cart = Handel::Cart->search({id => '11111111-1111-1111-1111-111111111111'});

    print $cart->subtotal;              # 12.9
    print $cart->subtotal->as_string;   # 12.90 USD

Each Handel::Currency object will stringify to the original value except in
string context, where it stringifies to the format specified in C<format>.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: $price [, $code, $format]

=back

To creates a new Handel::Currency object, simply call C<new> and pass in the
price to be formatted:

    my $currency = Handel::Currency->new(10.23);

You can also pass in the default currency code and/or currency format to be
used. If no code or format are supplied, future calls to C<format>, C<code> and
C<convert> will use the C<HandelCurrencyCode> and C<HandelCurrencyFormat>
environment variables.

=head1 METHODS

=head2 as_string

=over

=item Arguments: $format

=back

Returns the freshly formatted price in a format declared in
L<Locale::Currency::Format|Locale::Currency::Format>. If no format options are
specified, the defaults values from C<new> and then
C<HandelCurrencyFormat> are used. Currently the default format is
C<FMT_STANDARD>.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

=head2 code

=over

=item Arguments: $code

=back

Gets/sets the three letter currency code for the current currency object.

C<code> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code. If no code was passed during object
creation, I<no code will be return by this method> unless C<HandelCurrencyCode>
is set.

=head2 convert

=over

=item Arguments: $code

=back

Returns a new Handel::Currency object containing the converted price value.

If no C<code> is specified for the current currency object, the
C<HandelCurrencyCode> will be used as the currency code to convert from. If the
currency you are converting to is the same as the currency objects current
currency code, convert will just return itself.

You can also chain the C<convert> call into other method calls:

    my $price = Handel::Currency->new(1.25, 'USA');
    print $price->convert('CAD')->format('FMT_STANDARD')->as_string;

C<convert> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't valid currency code or isn't defined.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

=head2 converter_class

=over

=item Arguments: $converter_class

=back

Gets/sets the converter class to be used when converting currency numbers.

    __PACKAGE__->currency_class('MyCurrencyConverter');

The converter class can be any class that supports the following method
signature:

    sub convert {
        my ($self, $price, $from, $to) = @_;

        return $converted_price;
    };

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

=head2 format

=over

=item Arguments: $format

=back

Gets/sets the format to be used when displaying this object as a formatted
currency string.

If no format is defined, the defaults value C<HandelCurrencyFormat> is used.
Currently the default format is C<FMT_STANDARD>.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

=head2 name

Returns the currency name for the current objects currency code. If no
currency code is set, the code set in C<HandelCurrencyCode> will be used.

C<name> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if code used isn't a valid currency code.

=head2 stringify

Sames as C<as_string>.

=head2 value

Returns the original price value given to C<new>. Always use this instead of
relying on stringification when deflating currency objects in DBIx::Class
schemas.

=head2 get_component_class

=over

=item Arguments: $name

=back

Gets the current class for the specified component name.

    my $class = $self->get_component_class('item_class');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_class

=over

=item Arguments: $name, $value

=back

Sets the current class for the specified component name.

    $self->set_component_class('item_class', 'MyItemClass');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

There is no good reason to use this. Use the specific class accessors instead.

=head1 CONFIGURATION

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<new>.
See L<Locale::Currency::Format|Locale::Currency::Format> for all available
currency codes. The default code is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format|Locale::Currency::Format> for all available currency
codes. The default format used is C<FMT_STANDARD>. Just like in
Locale::Currency::Format, you can combine options using C<|>.

=head1 SEE ALSO

L<Data::Currency>, L<Locale::Currency>, L<Locale::Currency::Format>,
L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
