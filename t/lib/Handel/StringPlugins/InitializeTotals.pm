# $Id: /local/CPAN/Handel/t/lib/Handel/TestPipeline/InitializeTotals.pm 1043 2007-06-24T15:35:46.298350Z claco  $
package Handel::StringPlugins::InitializeTotals;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler('CHECKOUT_PHASE_STRING', \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    if (my $order = $ctx->order) {

        my $subtotal = 0;

        eval {
            my @items = $order->items;
            foreach my $item (@items) {
                $item->total($item->quantity*$item->price);
                $subtotal += $item->total;
            };
            $order->subtotal($subtotal);
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
