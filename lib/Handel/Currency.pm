# $Id$
package Handel::Currency;
use strict;
use warnings;
use overload '""' => \&stringify, fallback => 1;
use Handel::ConfigReader;

sub new {
    my ($class, $value) = @_;
    my $self = bless {_price => $value}, ref($class) || $class;

    return $self;
};

sub format {
    my ($self, $code, $format) = @_;

    eval 'use Locale::Currency::Format';
    return $self->{_price} if $@;

    my $cfg = Handel::ConfigReader->new();

    eval '$format = ' .  ($format || $cfg->{'HandelCurrencyFormat'});
    $code   ||= $cfg->{'HandelCurrencyCode'};

    return currency_format($code, $self->{_price}, $format);
};

sub stringify {
    my $self = shift;

    return $self->{_price};
};

1;
__END__

=head1 NAME

Handel::Currency - Price container to do currency formatting

=head1 SYNOPSIS

    use Handel::Currency;

    my $curr = Handel::Currenct-new(1.2);
    print $curr->format();          # 1.20 USD
    print $curr->format('CAD');     # 1.20 CAD
    print $curr->format(undef, 'FMT_SYMBOL');   # $1.20

=head1 DESCRIPTION

The Handel::Currency module provides basic currency formatting within Handel.
It can be used seperately to format any number into a more friendly format:

    my $price = 1.23;
    my $currency = Handel::Currency->new($price);

    print $currency->format;

A new Handel::Currency object is automatically returned within the shopping cart
when calling C<subtotal>, C<total>, and C<price> as an lvalue:

    my $cart = Handel::Cart->load({id => '11111111-1111-1111-1111-111111111111'});

    print $cart->subtotal;              # 12.9
    print $cart->subtotal->format();    # 12.90 USD

By default, a Handel::Currency object will stringify to the original decimal
based price.

=head1 CONSTRUCTOR

The create a new Handel::Currency instance, simply call C<new> and pass in the price
to be formated:

    my $currency = Handel::Currency->new(10.23);

=head1 METHODS

=head2 format( [$currencycode, $formatoptions] )

The C<format> method returns the freshly formatted price in a currency and format
declared in L<Locale::Currency::Format>. If no currency code or format are specified,
the defaults values from C<Handel::ConfigReader> are used. Currencly those defaults
are C<USD> and C<FMT_STANDARD>.

It is also acceptable to specify different default values. See L</"CONFIGURATION">
and L<Handel::ConfigReader> for further details.

In situations where C<Locale::Currency::Format> isn't installed, C<format> simply
returns the price in it's original format no harm no foul.

=head1 CONFIGURATION

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<format>.
See L<Locale::Currency::Format> for all available currency codes. The default code
is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format> for all available currency codes. The default format
used is C<FMT_STANDARD>. Just like in C<Locale::Currency::Format>, you can combine
options using C<|>.

=head1 SEE ALSO

L<Locale::Currency::Format>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
