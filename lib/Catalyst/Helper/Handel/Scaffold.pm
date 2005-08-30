# $Id$
package Catalyst::Helper::Handel::Scaffold;
use strict;
use warnings;
use Path::Class;
use File::Find::Rule;

sub setup {
    my ($self, $helper) = @_;

    ## all this hackery jiggery pokery assumes that sometimes M/V/C aren't just in
    ## lib/MyApp. Sometimes, they're different: MyApp/lib/MyApp/Catalyst/M|V|C
    $helper->{'root'}         = dir($helper->{'base'}, 'root');
    $helper->{'handel_dir'}   = dir($helper->{'base'}, 'root', 'handel');
    ($helper->{'c_dir'})      = find(name => 'C', in => dir($helper->{base}, 'lib'));
    ($helper->{'m_dir'})      = find(name => 'M', in => dir($helper->{base}, 'lib'));
    ($helper->{'c_test_dir'}) = find(name => 'C', in => dir($helper->{base}, 't'));
    ($helper->{'m_test_dir'}) = find(name => 'M', in => dir($helper->{base}, 't'));

    $helper->{'template_cart_view'}         = dir('handel', 'cart.tt');
    $helper->{'template_cart_products'}     = dir('handel', 'products.tt');
    $helper->{'template_checkout_edit'}     = dir('handel', 'edit.tt');
    $helper->{'template_checkout_preview'}  = dir('handel', 'preview.tt');
    $helper->{'template_checkout_payment'}  = dir('handel', 'payment.tt');
    $helper->{'template_checkout_complete'} = dir('handel', 'complete.tt');

    my @dirs = dir($helper->{'c_dir'})->dir_list;
    my @class;

    ## ditch C
    pop @dirs;

    ## work our way back up to lib and ditch the rest
    while (my $dir = pop @dirs) {
        last if $dir eq 'lib';
        push @class, $dir
    };

    $helper->{'base_class'}          = join '::', reverse @class;
    $helper->{'cart_controller'}     = $helper->{'base_class'} . '::C::Cart';
    $helper->{'checkout_controller'} = $helper->{'base_class'} . '::C::Checkout';
    $helper->{'cart_model'}          = $helper->{'base_class'} . '::M::Cart';
    $helper->{'order_model'}         = $helper->{'base_class'} . '::M::Order';

};


sub mk_stuff {
    my ($self, $helper, $dsn, $username, $password) = @_;

    $helper->{dsn}      = $dsn;
    $helper->{username} = $username;
    $helper->{password} = $password;

    $self->setup($helper);

    $helper->mk_component($helper->{'base_class'}, 'view', 'TT', 'TT');

    $helper->mk_dir($helper->{'handel_dir'});
    $helper->render_file('cartpage',       file($helper->{'root'}, $helper->{'template_cart_view'}));
    $helper->render_file('productspage',   file($helper->{'root'}, $helper->{'template_cart_products'}));
    $helper->render_file('editpage',       file($helper->{'root'}, $helper->{'template_checkout_edit'}));
    $helper->render_file('previewpage',    file($helper->{'root'}, $helper->{'template_checkout_preview'}));
    $helper->render_file('paymentpage',    file($helper->{'root'}, $helper->{'template_checkout_payment'}));
    $helper->render_file('completepage',   file($helper->{'root'}, $helper->{'template_checkout_complete'}));

    $helper->render_file('cartcontroller',     file($helper->{'c_dir'}, 'Cart.pm'));
    $helper->render_file('checkoutcontroller', file($helper->{'c_dir'}, 'Checkout.pm'));
    $helper->render_file('cartmodel',          file($helper->{'m_dir'}, 'Cart.pm'));
    $helper->render_file('ordermodel',         file($helper->{'m_dir'}, 'Order.pm'));
};

1;

__DATA__

__cartcontroller__
package [% cart_controller %];
use strict;
use warnings;
use Handel::Constants qw( :returnas :cart);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;

    if (!$c->req->cookie('cartid')) {
        $c->stash->{'cartid'} = [% cart_model %]->uuid;
        $c->res->cookies->{'cartid'} = {value => $c->stash->{'cartid'}, path => '/'};

        $c->stash->{'cart'} = [% cart_model %]->new({
            id   => $c->stash->{'cartid'},
            type => 0
        });
    } else {
        $c->stash->{'cartid'} = $c->req->cookie('cartid')->value;

        $c->stash->{'cart'} = [% cart_model %]->load({
            id   => $c->stash->{'cartid'},
            type => 0
        });

        if (!$c->stash->{'cart'}) {
            $c->stash->{'cart'} = [% cart_model %]->new({
                id   => $c->stash->{'cartid'},
                type => CART_TYPE_TEMP
            });
        };
    };
};

sub end : Private {
    my ($self, $c) = @_;

    $c->forward('[% base_class %]::V::TT') unless $c->res->output;
};

sub default : Private {
    my ($self, $c) = @_;

    $c->forward('view');
};

sub view : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_cart_view %]';
};

sub add : Local {
    my ($self, $c) = @_;
    my $sku         = $c->request->param('sku');
    my $quantity    = $c->request->param('quantity');
    my $price       = $c->request->param('price');
    my $description = $c->request->param('description');

    $quantity ||= 1;

    if ($c->req->method eq 'POST') {
        $c->stash->{'cart'}->add({
            sku         => $sku,
            quantity    => $quantity,
            price       => $price,
            description => $description
        });
    };

    $c->res->redirect($c->req->base . 'cart/');
};

sub update : Local {
    my ($self, $c) = @_;
    my $id       = $c->request->param('id');
    my $quantity = $c->request->param('quantity');

    if ($id && $quantity && $c->req->method eq 'POST') {
        my $item = $c->stash->{'cart'}->items({
            id => $id
        });

        if ($item) {
            $item->quantity($quantity);
        };

        undef $item;
    };

    $c->res->redirect($c->req->base . 'cart/');
};

sub clear : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        $c->stash->{'cart'}->clear;
    };

    $c->res->redirect($c->req->base . 'cart/');
};

sub delete : Local {
    my ($self, $c) = @_;
    my $id = $c->request->param('id');

    if ($id && $c->req->method eq 'POST') {
        $c->stash->{'cart'}->delete({
            id => $id
        });
    };

    $c->res->redirect($c->req->base . 'cart/');
};

sub empty : Local {
    my ($self, $c) = @_;

    $c->forward('clear');
};

## this needs to go away before release
sub products : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_cart_products %]';
};

1;
__checkoutcontroller__
package [% checkout_controller %];
use strict;
use warnings;
use Handel::Constants qw(:returnas :checkout :order);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;

    if (!$c->req->cookie('cartid')) {
        $c->res->redirect('/cart/');
    } else {
        my $cart = [% cart_model %]->load({
            id => $c->req->cookie('cartid')->value
        });

        if (!$cart || $cart->count < 1) {
            $c->res->redirect('/cart/');
        } else {
            if (!$c->req->cookie('orderid')) {
                $c->stash->{'orderid'} = [% order_model %]->uuid;
                $c->res->cookies->{'orderid'} = {value => $c->stash->{'orderid'}};

                $c->stash->{'order'} = [% order_model %]->new({
                    id   => $c->stash->{'orderid'},
                    cart => $cart
                });
                $c->stash->{'order'}->subtotal($cart->subtotal);
                $c->stash->{'order'}->total($cart->subtotal);
            } else {
                $c->stash->{'orderid'} = $c->req->cookie('orderid')->value;
                $c->stash->{'order'} = [% order_model %]->load({
                    id   => $c->stash->{'orderid'},
                    type => 0
                });

                if (!$c->stash->{'order'}) {
                    $c->stash->{'order'} = [%order_model %]->new({
                        id   => $c->stash->{'orderid'},
                        cart => $cart,
                        type => ORDER_TYPE_TEMP
                    });
                };
            };
        };
    };
};

sub end : Private {
    my ($self, $c) = @_;

    $c->forward('[% base_class %]::V::TT') unless $c->res->output;
};

sub default : Private {
    my ($self, $c) = @_;

    $c->forward('edit');
};

sub edit : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_checkout_edit %]';
};

sub update : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $order = $c->stash->{'order'};

        foreach my $param ($c->request->param) {
            $order->autoupdate(0);
            if ($order->can($param)) {
                if (($order->$param || '') ne ($c->req->param($param || ''))) {
                    $order->$param($c->req->param($param));
                };
            };
            $order->autoupdate(1);
            $order->update;
        };

        $c->res->redirect('/checkout/preview/');
    } else {
        $c->res->redirect('/checkout/');
    };
};

sub preview : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_checkout_preview %]';
};

sub payment : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_checkout_payment %]';

    if ($c->req->method eq 'POST') {
        my $order = $c->stash->{'order'};

        $order->autoupdate(0);
        $order->number(join '', localtime);
        $order->updated(scalar localtime);
        $order->autoupdate(1);
        $order->update;

        $c->res->redirect('/checkout/complete/');
    };
};

sub complete : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% template_checkout_complete %]';
};

1;
__cartmodel__
package [% cart_model %];
use strict;
use warnings;
use base 'Handel::Cart';

## this is a crappy hack. I need to get configreader scope straightened out
{
    $^W = 0;
    Handel::DBI->connection('[% dsn %]', '[% username %]', '[% password %]');
};

1;
__ordermodel__
package [% order_model %];
use strict;
use warnings;
use base 'Handel::Order';

## this is a crappy hack. I need to get configreader scope straightened out
{
    $^W = 0;
    Handel::DBI->connection('[% dsn %]', '[% username %]', '[% password %]');
};

1;
__cartpage__
[% TAGS [- -] %]
<h1>Your Shopping Cart</h1>
<p>
    <a href="/cart/products/">View Products</a> |
    <a href="/cart/">View Cart</a> |
    <a href="/checkout/">Checkout</a>
</p>
[% IF cart.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">SKU</th>
            <th align="left">Description</th>
            <th align="right">Price</th>
            <th align="center">Quantity</th>
            <th align="right">Total</th>
            <th colspan="2"></th>
        </tr>
    [% FOREACH item = cart.items %]
        <tr>
            <form action="/cart/update" method="post">
                <input type="hidden" name="id" value="[% item.id %]">
                <td align="left">[% item.sku %]</td>
                <td align="left">[% item.description %]</td>
                <td align="right">[% item.price.format(undef, 'FMT_SYMBOL') %]</td>
                <td align="center"><input style="text-align: center;" type="text" size="3" name="quantity" value="[% item.quantity %]"></td>
                <td align="right">[% item.total.format(undef, 'FMT_SYMBOL') %]</td>
                <td><input type="submit" value="Update"></td>
            </form>
            <form action="/cart/delete" method="post">
                <input type="hidden" name="id" value="[% item.id %]">
                <td>
                    <input type="submit" value="Delete">
                </td>
            </form>
        </tr>
    [% END %]
        <tr>
            <td colspan="7" height="20"></td>
        </tr>
        <tr>
            <th colspan="4" align="right">Subtotal:</th>
            <td align="right">[% cart.subtotal.format(undef, 'FMT_SYMBOL') %]</td>
            <td colspan="2"></td>
        </tr>
        <tr>
            <td colspan="7" align="right">
                <form action="/cart/empty" method="post">
                    <input type="submit" value="Empty Cart">
                </form>
                <form action="/checkout/" method="get">
                    <input type="submit" value="Checkout">
                </form>
            </td>
        </tr>
    </table>
[% ELSE %]
    <p>Your shopping cart is empty.</p>
[% END %]
__productspage__
[% TAGS [- -] %]
<h1>Nifty New Products</h1>
<p>
    <a href="/cart/products/">View Products</a> |
    <a href="/cart/">View Cart</a> |
    <a href="/checkout/">Checkout</a>
</p>
<h2>Mendlefarg 3000</h2>
<p>
    It slices. It dices. It MVCs!
</p>
<form action="/cart/add" method="post">
    <input type="hidden" name="sku" value="MFG3000">
    <input type="hidden" name="description" value="Mendlefarg 3000">
    <input type="hidden" name="price" value="19.95">
    <input type="text" name="quantity" value="1" size="3">
    <input type="submit" value="Add To Cart">
</form>

<h2>Flimblebot 98</h2>
<p>
    The most advances flimble-based bot response software ever!
</p>
<form action="/cart/add" method="post">
    <input type="hidden" name="sku" value="FB98">
    <input type="hidden" name="description" value="Flimblebot 98 Single-User">
    <input type="hidden" name="price" value="129.33">
    <input type="text" name="quantity" value="1" size="3">
    <input type="submit" value="Add To Cart">
</form>
__previewpage__
[% TAGS [- -] %]
<h1>Order Preview</h1>
<p>
    <a href="/cart/products/">View Products</a> |
    <a href="/cart/">View Cart</a> |
    <a href="/checkout/edit/">Edit Billing/Shipping</a>
</p>

<table border="0" csllpadding="3" cellspacing="5">
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
                        <form action="/checkout/payment/" method="get">
                            <input type="submit" value="Continue">
                        </form>
                    </td>
                </tr>
            </table>
        </td>
    </td>
</table>
__completepage__
[% TAGS [- -] %]
<h1>Order Complete!</h1>

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
__editpage__
[% TAGS [- -] %]
<h1>Billing/Shipping Information</h1>
<p>
    <a href="/cart/products/">View Products</a> |
    <a href="/cart/">View Cart</a>
</p>
<form action="/checkout/update/" method="post">
    <table border="0" csllpadding="3" cellspacing="5">
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
__paymentpage__
[% TAGS [- -] %]
<h1>Payment Information</h1>
<p>
    <a href="/cart/products/">View Products</a> |
    <a href="/cart/">View Cart</a> |
    <a href="/checkout/preview/">Preview</a>
</p>
<form action="/checkout/payment" method="post">
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <td align="right">Credit Card Number:</td>
            <td align="left"><input type="text" name="ccn" value=""></td>
        </tr>
        <tr>
            <td align="right">Credit Card Expiration:</td>
            <td align="left"><input type="text" size="3" name="ccm" maxlength="2" value=""> / <input type="text" size="3" name="ccy" maxlength="2" value=""></td>
        </tr>
        <tr>
            <td colspan="2" align="right"><input type="submit" value="Complete Order"></td>
        </tr>
    </table>
</form>
__END__

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR