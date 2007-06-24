# $Id$
## no critic
package Handel::Compat::Currency;
use strict;
use warnings;
use overload '""' => \&stringify, fallback => 1;

BEGIN {
    use Handel;
    use Handel::Constraints qw(:all);
    use Handel::Exception;
    use Handel::L10N qw(translate);

    use Locale::Currency;
    use Locale::Currency::Format;
    use Finance::Currency::Convert::WebserviceX;
};

sub new {
    my ($class, $value) = @_;
    my $self = bless {price => $value}, $class;

    $self->{'converter'} = Finance::Currency::Convert::WebserviceX->new;

    return $self;
};

sub format {
    my ($self, $code, $format) = @_;
    my $cfg = Handel->config;

    if (!$format) {
        $format =  $cfg->{'HandelCurrencyFormat'};
    };

    eval '$format = ' .  $format;
    if (!$code) {
        $code = $cfg->{'HandelCurrencyCode'};
    };

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $code) . '.') unless
            constraint_currency_code($code);

    return _to_utf8(currency_format($code, $self->{'price'}, $format));
};

sub convert {
    my ($self, $from, $to, $format, $options) = @_;
    my $cfg = Handel->config;

    if (!$from) {
        $from = $cfg->{'HandelCurrencyCode'};
    };
    if (!$to) {
        $to = $cfg->{'HandelCurrencyCode'};
    };
    if (!$options) {
        $options = $cfg->{'HandelCurrencyFormat'};
    };

    eval '$options = ' . $options;

    return if uc($from) eq uc($to);

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $from) . '.') unless
            constraint_currency_code($from);

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $to) . '.') unless
            constraint_currency_code($to);

    my $result = defined $self->{'converter'} ?
        $self->{'converter'}->convert($self->{'price'}, $from, $to) :
        undef;

    if (defined $result && $format) {
        return _to_utf8(currency_format($to, $result, $options));
    };

    return $result;
};

sub stringify {
    my $self = shift;

    return $self->value;
};

sub value {
    my $self = shift;

    return $self->{'price'};
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

1;
__END__

=head1 NAME

Handel::Compat::Currency - Price container to do currency conversion/formatting

=head1 SYNOPSIS

    use Handel::Compat::Currency;

    MyStorage->currency_class('Handel::Compt::Currency');

    my $curr = Handel::Currency->new(1.2);
    print $curr->format();          # 1.20 USD
    print $curr->format('CAD');     # 1.20 CAD
    print $curr->format(undef, 'FMT_SYMBOL');   # $1.20

    print 'Your price in Canadian Dollars is: ';
    print $curr->convert('USD', 'CAD');

=head1 DESCRIPTION

The Handel::Currency module provides basic currency formatting within Handel.
It can be used separately to format any number into a more friendly format:

    my $price = 1.23;
    my $currency = Handel::Currency->new($price);

    print $currency->format;

A new Handel::Currency object is automatically returned within the shopping
cart when calling C<subtotal>, C<total>, and C<price> as an lvalue:

    my $cart = Handel::Cart->search({id => '11111111-1111-1111-1111-111111111111'});

    print $cart->subtotal;              # 12.9
    print $cart->subtotal->format();    # 12.90 USD

By default, a Handel::Currency object will stringify to the original decimal
based price.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: $price [, $code, $formatoptions]

=back

The create a new Handel::Currency instance, simply call C<new> and pass in the
price to be formatted:

    my $currency = Handel::Currency->new(10.23);

You can also pass in the default currency code and/or currency format to be used.

=head1 METHODS

=head2 code

=over

=item Arguments: $code

=back

Gets/sets the three letter currency code for the current currency object.

C<code> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code.

=head2 convert

=over

=item Arguments: $from, $to [, $format, $formatoptions]

=back

If no C<from> or C<formatoptions> is specified, the options passed to C<new>
and then C<HandelCurrencyCode> and C<HandelCurrencyFormat>  will be used instead.

C<convert> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<from> or C<to> aren't valid currency codes.

If C<format> is true, the result of the conversion will also be formatted
using the formatting options given or the default in C<new> and then
C<HandelCurrencyFormat>.

You can also simply chain the C<convert> call into a C<format> call.

    my $price = Handel::Currency->new(1.25);
    print $price->convert('USD', 'CAD')->format;

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

=item Arguments: $code [, $options]

=back

Returns the freshly formatted price in a currency and format declared in
L<Locale::Currency::Format|Locale::Currency::Format>. If no currency code or
format are specified, the defaults values from C<new> and then
C<Handel::ConfigReader> are used. Currently those defaults are C<USD> and
C<FMT_STANDARD>.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

C<format> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code.

=head2 name

=over

=item Arguments $code

=back

Returns the currency name for the specified currency code. If no currency code
is specified, the currency code for the current object will be used. If that
too is not specified, the code set in C<HandelCurrencyCode> will be used.

C<name> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code.

=head2 stringify

Returns C<value> in scalar context. For now, this returns the same thing that
was passed to C<new>. This maybe change in the future.

=head2 value

Returns the original price value given to C<new>. Always use this instead of
relying on stringification when deflating currency objects in DBIx::Class
schemas.

=head1 CONFIGURATION

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<format>.
See L<Locale::Currency::Format|Locale::Currency::Format> for all available
currency codes. The default code is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format|Locale::Currency::Format> for all available currency
codes. The default format used is C<FMT_STANDARD>. Just like in
Locale::Currency::Format, you can combine options using C<|>.

=head1 SEE ALSO

L<Locale::Currency>, L<Locale::Currency::Format>,
L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
