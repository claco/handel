# $Id$
package Catalyst::Helper::Controller::Handel::Checkout;
use strict;
use warnings;
use Path::Class;

sub mk_compclass {
    my ($self, $helper, $cmodel, $omodel) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $helper->{'cmodel'} = $cmodel ? $helper->{'app'} . '::M::' . $cmodel :
                         $helper->{'app'} . '::M::Cart';

    $helper->{'omodel'} = $omodel ? $helper->{'app'} . '::M::' . $omodel :
                         $helper->{'app'} . '::M::Orders';

    my $curi = $helper->{'cmodel'} =~ /^.*::M(odel)?::(.*)$/i ? lc($2) : 'cart';
    $curi =~ s/::/\//;
    $helper->{'curi'} = $curi;

    my $ouri = $helper->{'omodel'} =~ /^.*::M(odel)?::(.*)$/i ? lc($2) : 'orders';
    $curi =~ s/::/\//;
    $helper->{'ouri'} = $ouri;

    $helper->mk_dir($dir);
    #$helper->mk_component($helper->{'app'}, 'view', 'TT', 'TT');
    $helper->render_file('controller', $file);
    $helper->render_file('edit', file($dir, 'edit.tt'));
    $helper->render_file('preview', file($dir, 'preview.tt'));
    $helper->render_file('payment', file($dir, 'payment.tt'));
    $helper->render_file('complete', file($dir, 'complete.tt'));
};

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);
};

1;
__DATA__
__controller__
package [% class %];
use strict;
use warnings;
use Handel::Checkout;
use Handel::Constants qw(:returnas :order :checkout);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;
    my $shopper = $c->req->cookie('shopperid');

    if (!$shopper) {
        $c->res->redirect($c->base . '/[% curi %]/');
    } else {
        my $cart = [% cmodel %]->load({
            shopper => $shopper,
            type    => CART_TYPE_TEMP
        }, RETURNAS_ITERATOR)->first;

        if (!$cart || !$cart->count) {
            $c->res->redirect($c->base . '/[% curi %]/');
        } else {
            my $order = [% omodel %]->load({
                shopper => $shopper,
                type    => ORDER_TYPE_TEMP
            }, RETURNAS_ITERATOR)->first;

            if (!$order) {
                $order = [% omodel %]->new({
                    shopper => $shopper,
                    cart    => $cart
                });

                my $checkout = Handel::Checkout->new({
                    order   => $order,
                    phases => 'CHECKOUT_PHASE_INITIALIZE'
                });

                $c->stash->{'order'} = $checkout->order;

                if ($checkout->process == CHECKOUT_STATUS_OK) {

                } else {
                    $c->stash->{'messages'} = $checkout->messages;
                };
            } else {
                $c->stash->{'order'} = $order;
            };
        };
    }:
};

sub end : Private {
    my ($self, $c) = @_;

    $c->forward('[% app %]::V::TT') unless $c->res->output;
};

sub default : Local {
    my ($self, $c) = @_;

    $c->forward('edit');
};

sub edit : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% uri %]/edit.tt';
};

sub update : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $order = $c->stash->{'order'};
        if ($order) {
            $c->res->redirect($c->base . '/[% curi %]/');
        } else {
            foreach my $param ($c->req->param) {
                $order->autoupdate(0);
                if ($order->can($param)) {
                    if (($order->$param || '') ne ($c->req->param($param || ''))) {
                        $order->$param($c->req->param($param));
                    };
                };
                $order->autoupdate(1);
                $order->update;
            };

            my $checkout = Handel::Checkout->new({
                order  => $order,
                phases => 'CHECKOUT_PHASE_VALIDATE'
            });

            if ($checkout->process == CHECKOUT_STATUS_OK) {
                $c->res->redirect($c->base . '/[% uri %]/preview/');
            } else {
                $c->stash->{'messages'} = $checkout->messages;
                $c->stash->{'template'} = '[% uri %]/edit.tt';
            };
        };
    };
};

sub preview : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% uri %]/preview.tt';
};

sub payment : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% uri %]/payment.tt';

    if ($c->req->method eq 'POST') {
        my $order = $c->stash->{'order'};
        if ($order) {
            $c->res->redirect($c->base . '/[% curi %]/');
        } else {
            foreach my $param ($c->req->param) {
                if ($order->can($param)) {
                    if (($order->$param || '') ne ($c->req->param($param || ''))) {
                        $order->$param($c->req->param($param));
                    };
                };
            };

            my $checkout = Handel::Checkout->new({
                order  => $order,
                phases => 'CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_DELIVERY'
            });

            if ($checkout->process == CHECKOUT_STATUS_OK) {
                if (!$order->number) {
                    $order->autoupdate(0);
                    $order->number(join '', localtime);
                    $order->updated(scalar localtime);
                    $order->autoupdate(1);
                    $order->update;
                };
                $c->res->redirect($c->base . '/[% uri %]/complete/');
            } else {
                $c->stash->{'messages'} = $checkout->messages;
            };
        };
    };
};

sub complete : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% uri %]/complete.tt';
};

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__edit__
[% TAGS [- -] %]
<h1>Billing/Shipping Information</h1>
<p>
    <a href="[% base _ '[- curi -]/' %]">View Cart</a>
</p>
<form action="[% base _ '[- uri -]/update/' %]" method="post">
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th colspan="2" align="left">Billing</th>
            <th width="25"></th>
            <th colspan="2" align="left">Shipping</th>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">First Name:</td>
            <td align="left"><input type="text" name="billtofirstname" value="[% order.billtofirstname %]" tabindex="1"></td>
            <td></td>
            <td align="right">First Name:</td>
            <td align="left"><input type="text" name="shiptofirstname" value="[% order.shiptofirstname %]" tabindex="14"></td>
        </tr>
        <tr>
            <td align="right">Last Name:</td>
            <td align="left"><input type="text" name="billtolastname" value="[% order.billtolastname %]" tabindex="2"></td>
            <td></td>
            <td align="right">Last Name:</td>
            <td align="left"><input type="text" name="shiptolastname" value="[% order.shiptolastname %]" tabindex="15"></td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">Address:</td>
            <td align="left"><input type="text" name="billtoaddress1" value="[% order.billtoaddress1 %]" tabindex="3"></td>
            <td></td>
            <td align="right">Address:</td>
            <td align="left"><input type="text" name="shiptoaddress1" value="[% order.shiptoaddress1 %]" tabindex="16"></td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left"><input type="text" name="billtoaddress2" value="[% order.billtoaddress2 %]" tabindex="4"></td>
            <td></td>
            <td align="right"></td>
            <td align="left"><input type="text" name="shiptoaddress2" value="[% order.shiptoaddress2 %]" tabindex="17"></td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left"><input type="text" name="billtoaddress3" value="[% order.billtoaddress3 %]" tabindex="5"></td>
            <td></td>
            <td align="right"></td>
            <td align="left"><input type="text" name="shiptoaddress3" value="[% order.shiptoaddress3 %]" tabindex="18"></td>
        </tr>
        <tr>
            <td align="right">City:</td>
            <td align="left"><input type="text" name="billtocity" value="[% order.billtocity %]" tabindex="6"></td>
            <td></td>
            <td align="right">City:</td>
            <td align="left"><input type="text" name="shiptocity" value="[% order.shiptocity %]" tabindex="19"></td>
        </tr>
        <tr>
            <td align="right">State/Province:</td>
            <td align="left"><input type="text" name="billtostate" value="[% order.billtostate %]" tabindex="7"></td>
            <td></td>
            <td align="right">State/Province:</td>
            <td align="left"><input type="text" name="shiptostate" value="[% order.shiptostate %]" tabindex="20"></td>
        </tr>
        <tr>
            <td align="right">Zip/Postal Code:</td>
            <td align="left"><input type="text" name="billtozip" value="[% order.billtozip %]" tabindex="8"></td>
            <td></td>
            <td align="right">Zip/Postal Code:</td>
            <td align="left"><input type="text" name="shiptozip" value="[% order.shiptozip %]" tabindex="21"></td>
        </tr>
        <tr>
            <td align="right">Country:</td>
            <td align="left"><input type="text" name="billtocountry" value="[% order.billtocountry %]" tabindex="9"></td>
            <td></td>
            <td align="right">Country:</td>
            <td align="left"><input type="text" name="shiptocountry" value="[% order.shiptocountry %]" tabindex="22"></td>
        </tr>
        <tr>
            <td align="right">Day Phone:</td>
            <td align="left"><input type="text" name="billtodayphone" value="[% order.billtodayphone %]" tabindex="10"></td>
            <td></td>
            <td align="right">Day Phone:</td>
            <td align="left"><input type="text" name="shiptodayphone" value="[% order.shiptodayphone %]" tabindex="23"></td>
        </tr>
        <tr>
            <td align="right">Night Phone:</td>
            <td align="left"><input type="text" name="billtonightphone" value="[% order.billtonightphone %]" tabindex="11"></td>
            <td></td>
            <td align="right">Night Phone:</td>
            <td align="left"><input type="text" name="shiptonightphone" value="[% order.shiptonightphone %]" tabindex="24"></td>
        </tr>
        <tr>
            <td align="right">Fax:</td>
            <td align="left"><input type="text" name="billtofax" value="[% order.billtofax %]" tabindex="12"></td>
            <td></td>
            <td align="right">Fax:</td>
            <td align="left"><input type="text" name="shiptofax" value="[% order.shiptofax %]" tabindex="25"></td>
        </tr>
        <tr>
            <td align="right">Email:</td>
            <td align="left"><input type="text" name="billtoemail" value="[% order.billtoemail %]" tabindex="13"></td>
            <td></td>
            <td align="right">Email:</td>
            <td align="left"><input type="text" name="shiptoemail" value="[% order.shiptoemail %]" tabindex="26"></td>
        </tr>
        <tr>
            <td colspan="5" height="10">&nbsp;</td>
        </tr>
        <tr>
            <td colspan="5" align="right"><input type="submit" value="Continue" tabindex="27"></td>
        </tr>
    </table>
</form>
__preview__
[% TAGS [- -] %]
<h1>Order Preview</h1>
<p>
    <a href="[% base _ '[- ucri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/edit/' %]">Edit Billing/Shipping</a>
</p>

<table border="0" cellpadding="3" cellspacing="5">
    <tr>
        <th colspan="2" align="left">Billing</th>
        <th width="50"></th>
        <th colspan="2" align="left">Shipping</th>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">First Name:</td>
        <td align="left">[% order.billtofirstname %]</td>
        <td></td>
        <td align="right">First Name:</td>
        <td align="left">[% order.shiptofirstname %]</td>
    </tr>
    <tr>
        <td align="right">Last Name:</td>
        <td align="left">[% order.billtolastname %]</td>
        <td></td>
        <td align="right">Last Name:</td>
        <td align="left">[% order.shiptolastname %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">Address:</td>
        <td align="left">[% order.billtoaddress1 %]</td>
        <td></td>
        <td align="right">Address:</td>
        <td align="left">[% order.shiptoaddress1 %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% order.billtoaddress2 %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% order.shiptoaddress2 %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% order.billtoaddress3 %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% order.shiptoaddress3 %]</td>
    </tr>
    <tr>
        <td align="right">City:</td>
        <td align="left">[% order.billtocity %]</td>
        <td></td>
        <td align="right">City:</td>
        <td align="left">[% order.shiptocity %]</td>
    </tr>
    <tr>
        <td align="right">State/Province:</td>
        <td align="left">[% order.billtostate %]</td>
        <td></td>
        <td align="right">State/Province:</td>
        <td align="left">[% order.shiptostate %]</td>
    </tr>
    <tr>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% order.billtozip %]</td>
        <td></td>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% order.shiptozip %]</td>
    </tr>
    <tr>
        <td align="right">Country:</td>
        <td align="left">[% order.billtocountry %]</td>
        <td></td>
        <td align="right">Country:</td>
        <td align="left">[% order.shiptocountry %]</td>
    </tr>
    <tr>
        <td align="right">Day Phone:</td>
        <td align="left">[% order.billtodayphone %]</td>
        <td></td>
        <td align="right">Day Phone:</td>
        <td align="left">[% order.shiptodayphone %]</td>
    </tr>
    <tr>
        <td align="right">Night Phone:</td>
        <td align="left">[% order.billtonightphone %]</td>
        <td></td>
        <td align="right">Night Phone:</td>
        <td align="left">[% order.shiptonightphone %]</td>
    </tr>
    <tr>
        <td align="right">Fax:</td>
        <td align="left">[% order.billtofax %]</td>
        <td></td>
        <td align="right">Fax:</td>
        <td align="left">[% order.shiptofax %]</td>
    </tr>
    <tr>
        <td align="right">Email:</td>
        <td align="left">[% order.billtoemail %]</td>
        <td></td>
        <td align="right">Email:</td>
        <td align="left">[% order.shiptoemail %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td colspan="5">
            <table border="0" cellpadding="3" cellspacing="5" width="100%">
                <tr>
                    <th align="left">SKU</th>
                    <th align="left">Description</th>
                    <th align="right">Price</th>
                    <th align="center">Quantity</th>
                    <th align="right">Total</th>
                </tr>
            [% FOREACH item = order.items %]
                <tr>
                        <td align="left">[% item.sku %]</td>
                        <td align="left">[% item.description %]</td>
                        <td align="right">[% item.price.format(undef, 'FMT_SYMBOL') %]</td>
                        <td align="center">[% item.quantity %]</td>
                        <td align="right">[% item.total.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
            [% END %]
                <tr>
                        <td align="right" colspan="4">Tax:</td>
                        <td align="right">[% order.tax.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Shipping:</td>
                        <td align="right">[% order.shipping.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Handling:</td>
                        <td align="right">[% order.handling.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Total:</td>
                        <td align="right">[% order.total.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                    <td colspan="5" height="5">&nbsp;</td>
                </tr>
                <tr>
                    <td colspan="5" align="right">
                        <form action="[% base _ '[- uri -]/payment/' %]" method="get">
                            <input type="submit" value="Continue">
                        </form>
                    </td>
                </tr>
            </table>
        </td>
    </td>
</table>
__payment__
[% TAGS [- -] %]
<h1>Payment Information</h1>
<p>
    <a href="[% base _ '[- suri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/preview/' %]">Preview</a>
</p>
<form action="[% base _ '[- uri -]/payment/' %]" method="post">
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <td align="right">Name On Card:</td>
            <td align="left"><input type="text" name="ccname" value=""></td>
        </tr>
        <tr>
            <td align="right">Credit Card Number:</td>
            <td align="left"><input type="text" name="ccn" value=""></td>
        </tr>
        <tr>
            <td align="right">Credit Card Expiration:</td>
            <td align="left"><input type="text" size="3" name="ccm" maxlength="2" value=""> / <input type="text" size="3" name="ccy" maxlength="2" value=""></td>
        </tr>
        <tr>
            <td align="right">Credit Card Verificaton Number:</td>
            <td align="left"><input type="text" name="ccvn" value="" maxlength="4" size="5"></td>
        </tr>
        <tr>
            <td colspan="2" align="right"><input type="submit" value="Complete Order"></td>
        </tr>
    </table>
</form>
__complete__
[% TAGS [- -] %]
<h1>Order Complete!</h1>
<p>
    <a href="[% base _ '[- ouri -]/list/' %]">View Orders</a>
</p>
<table border="0" csllpadding="1" cellspacing="1">
    <tr>
        <td align="right">Order#:</td>
        <td align="left">[% order.number %]</td>
        <td width="50"></td>
        <td align="right">Submitted::</td>
        <td align="left">[% order.updated %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">First Name:</td>
        <td align="left">[% order.billtofirstname %]</td>
        <td width="50"></td>
        <td align="right">First Name:</td>
        <td align="left">[% order.shiptofirstname %]</td>
    </tr>
    <tr>
        <td align="right">Last Name:</td>
        <td align="left">[% order.billtolastname %]</td>
        <td></td>
        <td align="right">Last Name:</td>
        <td align="left">[% order.shiptolastname %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">Address:</td>
        <td align="left">[% order.billtoaddress1 %]</td>
        <td></td>
        <td align="right">Address:</td>
        <td align="left">[% order.shiptoaddress1 %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% order.billtoaddress2 %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% order.shiptoaddress2 %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% order.billtoaddress3 %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% order.shiptoaddress3 %]</td>
    </tr>
    <tr>
        <td align="right">City:</td>
        <td align="left">[% order.billtocity %]</td>
        <td></td>
        <td align="right">City:</td>
        <td align="left">[% order.shiptocity %]</td>
    </tr>
    <tr>
        <td align="right">State/Province:</td>
        <td align="left">[% order.billtostate %]</td>
        <td></td>
        <td align="right">State/Province:</td>
        <td align="left">[% order.shiptostate %]</td>
    </tr>
    <tr>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% order.billtozip %]</td>
        <td></td>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% order.shiptozip %]</td>
    </tr>
    <tr>
        <td align="right">Country:</td>
        <td align="left">[% order.billtocountry %]</td>
        <td></td>
        <td align="right">Country:</td>
        <td align="left">[% order.shiptocountry %]</td>
    </tr>
    <tr>
        <td align="right">Day Phone:</td>
        <td align="left">[% order.billtodayphone %]</td>
        <td></td>
        <td align="right">Day Phone:</td>
        <td align="left">[% order.shiptodayphone %]</td>
    </tr>
    <tr>
        <td align="right">Night Phone:</td>
        <td align="left">[% order.billtonightphone %]</td>
        <td></td>
        <td align="right">Night Phone:</td>
        <td align="left">[% order.shiptonightphone %]</td>
    </tr>
    <tr>
        <td align="right">Fax:</td>
        <td align="left">[% order.billtofax %]</td>
        <td></td>
        <td align="right">Fax:</td>
        <td align="left">[% order.shiptofax %]</td>
    </tr>
    <tr>
        <td align="right">Email:</td>
        <td align="left">[% order.billtoemail %]</td>
        <td></td>
        <td align="right">Email:</td>
        <td align="left">[% order.shiptoemail %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td colspan="5">
            <table border="0" cellpadding="3" cellspacing="5" width="100%">
                <tr>
                    <th align="left">SKU</th>
                    <th align="left">Description</th>
                    <th align="right">Price</th>
                    <th align="center">Quantity</th>
                    <th align="right">Total</th>
                </tr>
            [% FOREACH item = order.items %]
                <tr>
                        <td align="left">[% item.sku %]</td>
                        <td align="left">[% item.description %]</td>
                        <td align="right">[% item.price.format(undef, 'FMT_SYMBOL') %]</td>
                        <td align="center">[% item.quantity %]</td>
                        <td align="right">[% item.total.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
            [% END %]
                <tr>
                        <td align="right" colspan="4">Tax:</td>
                        <td align="right">[% order.tax.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Shipping:</td>
                        <td align="right">[% order.shipping.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Handling:</td>
                        <td align="right">[% order.handling.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Total:</td>
                        <td align="right">[% order.total.format(undef, 'FMT_SYMBOL') %]</td>
                </tr>
            </table>
        </td>
    </td>
</table>
__END__

=head1 NAME

Catalyst::Helper::Controller::Handel::Checkout - Helper for Handel::Checkout Controllers

=head1 SYNOPSIS

    script/create.pl controller <newclass> Handel::Checkout [<cartmodel> <ordermodel>]
    script/create.pl controller Checkout Handel::Checkout

=head1 DESCRIPTION

A Helper for creating controllers based on Handel::Checkout objects. IF no cartmodel or
ordermodel was specified, ::M::Cart and ::M::Orders is assumed.

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Checkout Controller class and template files for you.

=head2 mk_comptest

Makes a Handel::Checkout Controller test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Checkout>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/