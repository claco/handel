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
use Handel::Constants qw(:returnas :order :cart :checkout);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;
    my $shopperid = $c->req->cookie('shopperid')->value;

    if (!$shopperid) {
        $c->res->redirect($c->req->base . '[% curi %]/');
    } else {
        $c->stash->{'shopperid'} = $shopperid;

        my $cart = [% cmodel %]->load({
            shopper => $shopperid,
            type    => CART_TYPE_TEMP
        }, RETURNAS_ITERATOR)->first;

        if (!$cart || !$cart->count) {
            $c->res->redirect($c->req->base . '[% curi %]/');
        } else {
            my $order = [% omodel %]->load({
                shopper => $shopperid,
                type    => ORDER_TYPE_TEMP
            }, RETURNAS_ITERATOR)->first;

            if (!$order) {
                $order = MyApp::M::Orders->new({
                    shopper => $shopperid,
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
                $order->reconcile($cart);
                $c->stash->{'order'} = $order;
            };
        };
    };
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
        if (!$order) {
            $c->res->redirect($c->req->base . '[% curi %]/');
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
                $c->res->redirect($c->req->base . '[% uri %]/preview/');
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
        if (!$order) {
            $c->res->redirect($c->req->base . '[% curi %]/');
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
                phases => 'CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_FINALIZE, CHECKOUT_PHASE_DELIVERY'
            });

            if ($checkout->process == CHECKOUT_STATUS_OK) {
                [% cmodel %]->destroy({
                    shopper => $c->stash->{'shopperid'},
                    type      => CART_TYPE_TEMP
                });
                $c->forward('complete');
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
[% USE HTML %]
<h1>Billing/Shipping Information</h1>
<p>
    <a href="[% base _ '[- curi -]/' %]">View Cart</a>
</p>
[% IF messages %]
    <ul>
        [% FOREACH message IN messages %]
            <li>[% message %]</li>
        [% END %]
    </ul>
[% END %]
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
            <td align="left"><input type="text" name="billtofirstname" value="[% HTML.escape(order.billtofirstname) %]" tabindex="1"></td>
            <td></td>
            <td align="right">First Name:</td>
            <td align="left"><input type="text" name="shiptofirstname" value="[% HTML.escape(order.shiptofirstname) %]" tabindex="14"></td>
        </tr>
        <tr>
            <td align="right">Last Name:</td>
            <td align="left"><input type="text" name="billtolastname" value="[% HTML.escape(order.billtolastname) %]" tabindex="2"></td>
            <td></td>
            <td align="right">Last Name:</td>
            <td align="left"><input type="text" name="shiptolastname" value="[% HTML.escape(order.shiptolastname) %]" tabindex="15"></td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">Address:</td>
            <td align="left"><input type="text" name="billtoaddress1" value="[% HTML.escape(order.billtoaddress1) %]" tabindex="3"></td>
            <td></td>
            <td align="right">Address:</td>
            <td align="left"><input type="text" name="shiptoaddress1" value="[% HTML.escape(order.shiptoaddress1) %]" tabindex="16"></td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left"><input type="text" name="billtoaddress2" value="[% HTML.escape(order.billtoaddress2) %]" tabindex="4"></td>
            <td></td>
            <td align="right"></td>
            <td align="left"><input type="text" name="shiptoaddress2" value="[% HTML.escape(order.shiptoaddress2) %]" tabindex="17"></td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left"><input type="text" name="billtoaddress3" value="[% HTML.escape(order.billtoaddress3) %]" tabindex="5"></td>
            <td></td>
            <td align="right"></td>
            <td align="left"><input type="text" name="shiptoaddress3" value="[% HTML.escape(order.shiptoaddress3) %]" tabindex="18"></td>
        </tr>
        <tr>
            <td align="right">City:</td>
            <td align="left"><input type="text" name="billtocity" value="[% HTML.escape(order.billtocity) %]" tabindex="6"></td>
            <td></td>
            <td align="right">City:</td>
            <td align="left"><input type="text" name="shiptocity" value="[% HTML.escape(order.shiptocity) %]" tabindex="19"></td>
        </tr>
        <tr>
            <td align="right">State/Province:</td>
            <td align="left"><input type="text" name="billtostate" value="[% HTML.escape(order.billtostate) %]" tabindex="7"></td>
            <td></td>
            <td align="right">State/Province:</td>
            <td align="left"><input type="text" name="shiptostate" value="[% HTML.escape(order.shiptostate) %]" tabindex="20"></td>
        </tr>
        <tr>
            <td align="right">Zip/Postal Code:</td>
            <td align="left"><input type="text" name="billtozip" value="[% HTML.escape(order.billtozip) %]" tabindex="8"></td>
            <td></td>
            <td align="right">Zip/Postal Code:</td>
            <td align="left"><input type="text" name="shiptozip" value="[% HTML.escape(order.shiptozip) %]" tabindex="21"></td>
        </tr>
        <tr>
            <td align="right">Country:</td>
            <td align="left"><input type="text" name="billtocountry" value="[% HTML.escape(order.billtocountry) %]" tabindex="9"></td>
            <td></td>
            <td align="right">Country:</td>
            <td align="left"><input type="text" name="shiptocountry" value="[% HTML.escape(order.shiptocountry) %]" tabindex="22"></td>
        </tr>
        <tr>
            <td align="right">Day Phone:</td>
            <td align="left"><input type="text" name="billtodayphone" value="[% HTML.escape(order.billtodayphone) %]" tabindex="10"></td>
            <td></td>
            <td align="right">Day Phone:</td>
            <td align="left"><input type="text" name="shiptodayphone" value="[% HTML.escape(order.shiptodayphone) %]" tabindex="23"></td>
        </tr>
        <tr>
            <td align="right">Night Phone:</td>
            <td align="left"><input type="text" name="billtonightphone" value="[% HTML.escape(order.billtonightphone) %]" tabindex="11"></td>
            <td></td>
            <td align="right">Night Phone:</td>
            <td align="left"><input type="text" name="shiptonightphone" value="[% HTML.escape(order.shiptonightphone) %]" tabindex="24"></td>
        </tr>
        <tr>
            <td align="right">Fax:</td>
            <td align="left"><input type="text" name="billtofax" value="[% HTML.escape(order.billtofax) %]" tabindex="12"></td>
            <td></td>
            <td align="right">Fax:</td>
            <td align="left"><input type="text" name="shiptofax" value="[% HTML.escape(order.shiptofax) %]" tabindex="25"></td>
        </tr>
        <tr>
            <td align="right">Email:</td>
            <td align="left"><input type="text" name="billtoemail" value="[% HTML.escape(order.billtoemail) %]" tabindex="13"></td>
            <td></td>
            <td align="right">Email:</td>
            <td align="left"><input type="text" name="shiptoemail" value="[% HTML.escape(order.shiptoemail) %]" tabindex="26"></td>
        </tr>
        <tr>
            <td colspan="5" height="10">&nbsp;</td>
        </tr>
        <tr>
            <td align="right" valign="top">Comments:</td>
            <td colspan="4" valign="top">
                <textarea name="comments" cols="45" rows="10">[% HTML.escape(order.comments) %]</textarea>
            </td>
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
[% USE HTML %]
<h1>Order Preview</h1>
<p>
    <a href="[% base _ '[- curi -]/' %]">View Cart</a> |
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
        <td align="left">[% HTML.escape(order.billtofirstname) %]</td>
        <td></td>
        <td align="right">First Name:</td>
        <td align="left">[% HTML.escape(order.shiptofirstname) %]</td>
    </tr>
    <tr>
        <td align="right">Last Name:</td>
        <td align="left">[% HTML.escape(order.billtolastname) %]</td>
        <td></td>
        <td align="right">Last Name:</td>
        <td align="left">[% HTML.escape(order.shiptolastname) %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">Address:</td>
        <td align="left">[% HTML.escape(order.billtoaddress1) %]</td>
        <td></td>
        <td align="right">Address:</td>
        <td align="left">[% HTML.escape(order.shiptoaddress1) %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.billtoaddress2) %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.shiptoaddress2) %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.billtoaddress3) %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.shiptoaddress3) %]</td>
    </tr>
    <tr>
        <td align="right">City:</td>
        <td align="left">[% HTML.escape(order.billtocity) %]</td>
        <td></td>
        <td align="right">City:</td>
        <td align="left">[% HTML.escape(order.shiptocity) %]</td>
    </tr>
    <tr>
        <td align="right">State/Province:</td>
        <td align="left">[% HTML.escape(order.billtostate) %]</td>
        <td></td>
        <td align="right">State/Province:</td>
        <td align="left">[% HTML.escape(order.shiptostate) %]</td>
    </tr>
    <tr>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% HTML.escape(order.billtozip) %]</td>
        <td></td>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% HTML.escape(order.shiptozip) %]</td>
    </tr>
    <tr>
        <td align="right">Country:</td>
        <td align="left">[% HTML.escape(order.billtocountry) %]</td>
        <td></td>
        <td align="right">Country:</td>
        <td align="left">[% HTML.escape(order.shiptocountry) %]</td>
    </tr>
    <tr>
        <td align="right">Day Phone:</td>
        <td align="left">[% HTML.escape(order.billtodayphone) %]</td>
        <td></td>
        <td align="right">Day Phone:</td>
        <td align="left">[% HTML.escape(order.shiptodayphone) %]</td>
    </tr>
    <tr>
        <td align="right">Night Phone:</td>
        <td align="left">[% HTML.escape(order.billtonightphone) %]</td>
        <td></td>
        <td align="right">Night Phone:</td>
        <td align="left">[% HTML.escape(order.shiptonightphone) %]</td>
    </tr>
    <tr>
        <td align="right">Fax:</td>
        <td align="left">[% HTML.escape(order.billtofax) %]</td>
        <td></td>
        <td align="right">Fax:</td>
        <td align="left">[% HTML.escape(order.shiptofax) %]</td>
    </tr>
    <tr>
        <td align="right">Email:</td>
        <td align="left">[% HTML.escape(order.billtoemail) %]</td>
        <td></td>
        <td align="right">Email:</td>
        <td align="left">[% HTML.escape(order.shiptoemail) %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right" valign="top">Comments:</td>
        <td colspan="4" valign="top">[% HTML.escape(order.comments) %]</td>
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
                        <td align="left">[% HTML.escape(item.sku) %]</td>
                        <td align="left">[% HTML.escape(item.description) %]</td>
                        <td align="right">[% HTML.escape(item.price.format(undef, 'FMT_SYMBOL')) %]</td>
                        <td align="center">[% HTML.escape(item.quantity) %]</td>
                        <td align="right">[% HTML.escape(item.total.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
            [% END %]
                <tr>
                        <td align="right" colspan="4">Subtotal:</td>
                        <td align="right">[% HTML.escape(order.subtotal.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Tax:</td>
                        <td align="right">[% HTML.escape(order.tax.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Shipping:</td>
                        <td align="right">[% HTML.escape(order.shipping.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Handling:</td>
                        <td align="right">[% HTML.escape(order.handling.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Total:</td>
                        <td align="right">[% HTML.escape(order.total.format(undef, 'FMT_SYMBOL')) %]</td>
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
[% USE HTML %]
<h1>Payment Information</h1>
<p>
    <a href="[% base _ '[- curi -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/preview/' %]">Preview</a>
</p>
[% IF messages %]
    <ul>
        [% FOREACH message IN messages %]
            <li>[% message %]</li>
        [% END %]
    </ul>
[% END %]
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
[% USE HTML %]
<h1>Order Complete!</h1>
<p>
    <a href="[% base _ '[- ouri -]/list/' %]">View Orders</a>
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
        <td align="left">[% HTML.escape(order.billtofirstname) %]</td>
        <td></td>
        <td align="right">First Name:</td>
        <td align="left">[% HTML.escape(order.shiptofirstname) %]</td>
    </tr>
    <tr>
        <td align="right">Last Name:</td>
        <td align="left">[% HTML.escape(order.billtolastname) %]</td>
        <td></td>
        <td align="right">Last Name:</td>
        <td align="left">[% HTML.escape(order.shiptolastname) %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right">Address:</td>
        <td align="left">[% HTML.escape(order.billtoaddress1) %]</td>
        <td></td>
        <td align="right">Address:</td>
        <td align="left">[% HTML.escape(order.shiptoaddress1) %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.billtoaddress2) %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.shiptoaddress2) %]</td>
    </tr>
    <tr>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.billtoaddress3) %]</td>
        <td></td>
        <td align="right"></td>
        <td align="left">[% HTML.escape(order.shiptoaddress3) %]</td>
    </tr>
    <tr>
        <td align="right">City:</td>
        <td align="left">[% HTML.escape(order.billtocity) %]</td>
        <td></td>
        <td align="right">City:</td>
        <td align="left">[% HTML.escape(order.shiptocity) %]</td>
    </tr>
    <tr>
        <td align="right">State/Province:</td>
        <td align="left">[% HTML.escape(order.billtostate) %]</td>
        <td></td>
        <td align="right">State/Province:</td>
        <td align="left">[% HTML.escape(order.shiptostate) %]</td>
    </tr>
    <tr>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% HTML.escape(order.billtozip) %]</td>
        <td></td>
        <td align="right">Zip/Postal Code:</td>
        <td align="left">[% HTML.escape(order.shiptozip) %]</td>
    </tr>
    <tr>
        <td align="right">Country:</td>
        <td align="left">[% HTML.escape(order.billtocountry) %]</td>
        <td></td>
        <td align="right">Country:</td>
        <td align="left">[% HTML.escape(order.shiptocountry) %]</td>
    </tr>
    <tr>
        <td align="right">Day Phone:</td>
        <td align="left">[% HTML.escape(order.billtodayphone) %]</td>
        <td></td>
        <td align="right">Day Phone:</td>
        <td align="left">[% HTML.escape(order.shiptodayphone) %]</td>
    </tr>
    <tr>
        <td align="right">Night Phone:</td>
        <td align="left">[% HTML.escape(order.billtonightphone) %]</td>
        <td></td>
        <td align="right">Night Phone:</td>
        <td align="left">[% HTML.escape(order.shiptonightphone) %]</td>
    </tr>
    <tr>
        <td align="right">Fax:</td>
        <td align="left">[% HTML.escape(order.billtofax) %]</td>
        <td></td>
        <td align="right">Fax:</td>
        <td align="left">[% HTML.escape(order.shiptofax) %]</td>
    </tr>
    <tr>
        <td align="right">Email:</td>
        <td align="left">[% HTML.escape(order.billtoemail) %]</td>
        <td></td>
        <td align="right">Email:</td>
        <td align="left">[% HTML.escape(order.shiptoemail) %]</td>
    </tr>
    <tr>
        <td colspan="5" height="5">&nbsp;</td>
    </tr>
    <tr>
        <td align="right" valign="top">Comments:</td>
        <td colspan="4" valign="top">[% HTML.escape(order.comments) %]</td>
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
                        <td align="left">[% HTML.escape(item.sku) %]</td>
                        <td align="left">[% HTML.escape(item.description) %]</td>
                        <td align="right">[% HTML.escape(item.price.format(undef, 'FMT_SYMBOL')) %]</td>
                        <td align="center">[% HTML.escape(item.quantity) %]</td>
                        <td align="right">[% HTML.escape(item.total.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
            [% END %]
                <tr>
                        <td align="right" colspan="4">Subtotal:</td>
                        <td align="right">[% HTML.escape(order.subtotal.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Tax:</td>
                        <td align="right">[% HTML.escape(order.tax.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Shipping:</td>
                        <td align="right">[% HTML.escape(order.shipping.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Handling:</td>
                        <td align="right">[% HTML.escape(order.handling.format(undef, 'FMT_SYMBOL')) %]</td>
                </tr>
                <tr>
                        <td align="right" colspan="4">Total:</td>
                        <td align="right">[% HTML.escape(order.total.format(undef, 'FMT_SYMBOL')) %]</td>
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