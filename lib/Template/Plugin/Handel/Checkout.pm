# $Id$
package Template::Plugin::Handel::Checkout;
use strict;
use warnings;
use base qw/Template::Plugin/;
use Handel::Constants ();

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {_CONTEXT => $context}, 'Template::Plugin::Handel::Checkout::Proxy';

    foreach my $const (@Handel::Constants::EXPORT_OK) {
        if ($const =~ /^[A-Z]{1}/) {
            $self->{$const} = Handel::Constants->$const;
        };
    };
    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

package Template::Plugin::Handel::Checkout::Proxy;
use strict;
use warnings;
use Template::Plugin::Handel::Order;
use base qw/Handel::Checkout/;

sub new {
    my $class = ref shift;

    return $class->SUPER::new(@_);
};

sub order {
    my ($self, @args) = @_;

    my $order = $self->SUPER::order(@args);

    return bless \%{$order}, 'Template::Plugin::Handel::Order::Proxy';
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Checkout - Template Toolkit plugin for checkout processing

=head1 SYNOPSIS

    [% USE Handel.Checkout %]
    [% IF (checkout = Handel.Checkout.new({order => 'A2CCD312-73B5-4EE4-B77E-3D027349A055'})) %]
        [% checkout.process %]
        [% FOREACH message IN checkout.messages %]
            [% message.text %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

Template::Plugin::Handel::Checkout is a TT2 (Template Toolkit 2) plugin for
Handel::Checkout. It's API is exactly the same as Handel::Checkout.

Handel::Constants are imported into this module automatically. This removes
the need to use Template::Plugin::Handel::Constants separately when working
with checkout processes.

    [% USE hc = Handel.Checkout %]
    [% checkout = hc.new(...) %]
    [% checkout.order.type(hc.CHECKOUT_PHASE_INITIALIZE) %]

=head1 SEE ALSO

L<Template::Plugin::Handel::Constants>, L<Handel::Constants>, L<Handel::Checkout>,
L<Template::Plugin>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
