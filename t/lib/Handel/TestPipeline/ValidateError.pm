# $Id$
package Handel::TestPipeline::ValidateError;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler(CHECKOUT_PHASE_VALIDATE, \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    if (my $order = $ctx->order) {

        my $subtotal = 0;

        eval {
            my @items = $order->items;
            foreach my $item (@items) {
                $item->sku('ERRORSKU');
            };
            $order->billtofirstname('ErrorBillToFirstName');
            $order->billtolastname('ErrorBillToLastName');

            die 'ValidateError';
        };

        if ($@) {
            $ctx->add_message($@);
            return CHECKOUT_HANDLER_ERROR;
        } else {
            return CHECKOUT_HANDLER_OK;
        };
    } else {
        $ctx->add_message('No order was loaded');

        return CHECKOUT_HANDLER_ERROR;
    };
};

1;
