# $Id$
package Handel::Checkout::Plugin::AssignOrderNumber;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler(CHECKOUT_PHASE_FINALIZE, \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    $ctx->order->number(time);
    $ctx->order->updated(scalar localtime);

    return CHECKOUT_HANDLER_OK;
};

1;

=head1 NAME

Handel::Checkout::Plugin::AssignOrderNumber - Checkout plugin to assign order numbers

=head1 SYNOPSIS

    use Handel::Checkout;

    my $checkout = Handel::Checkout->new({
        order       => $order,
        phases      => 'CHECKOUT_PHASE_FINALIZE',
        loadplugins => 'Handel::Checkout::Plugin::AssignOrderNumber'
    });

    $checkout->process;

=head1 DESCRIPTION

This checkout plugin simply assigns a number to $order->number during the
CHECKOUT_PHASE_FINALIZE phase.

=head1 SEE ALSO

L<Handel::Checkout::Plugin>, L<Handel::Checkout>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
