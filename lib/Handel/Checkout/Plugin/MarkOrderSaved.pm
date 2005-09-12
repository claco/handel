# $Id$
package Handel::Checkout::Plugin::MarkOrderSaved;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout :order);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler(CHECKOUT_PHASE_FINALIZE, \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    $ctx->order->type(ORDER_TYPE_SAVED);

    return CHECKOUT_HANDLER_OK;
};

1;

=head1 NAME

Handel::Checkout::Plugin::MarkOrderSaved - Checkout plugin to mark the order ORDER_TYPE_SAVED

=head1 SYNOPSIS

    use Handel::Checkout;

    my $checkout = Handel::Checkout->new({
        order       => $order,
        phases      => 'CHECKOUT_PHASE_FINALIZE',
        loadplugins => 'Handel::Checkout::Plugin::MarkOrderSaved'
    });

    $checkout->process;

=head1 DESCRIPTION

This checkout plugin simply changes $order->type to ORDER_TYPE_SAVED during the
CHECKOUT_PHASE_FINALIZE phase.

=head1 SEE ALSO

L<Handel::Checkout::Plugin>, L<Handel::Checkout>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
