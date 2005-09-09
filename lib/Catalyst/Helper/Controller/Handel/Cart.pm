# $Id$
package Catalyst::Helper::Controller::Handel::Cart;
use strict;
use warnings;
use Path::Class;

sub mk_compclass {
    my ($self, $helper, $model) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $helper->{'model'} = $model ? $helper->{'app'} . '::M::' . $model :
                         $helper->{'app'} . '::M::Cart';

    $helper->mk_dir($dir);
    $helper->render_file('controller', $file);
    $helper->render_file('view', file($dir, 'view.tt'));
    $helper->render_file('list', file($dir, 'list.tt'));
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
use Handel::Constants qw(:returnas :cart);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;

    if (!$c->req->cookie('shopperid')) {
        $c->stash->{'shopperid'} = [% model %]->uuid;
        $c->res->cookies->{'shopperid'} = {value => $c->stash->{'shopperid'}, path => '/'};

        $c->stash->{'cart'} = [% model %]->new({
            shopper => $c->stash->{'shopperid'},
            type    => CART_TYPE_TEMP
        });
    } else {
        $c->stash->{'shopperid'} = $c->req->cookie('shopperid')->value;

        $c->stash->{'cart'} = [% model %]->load({
            shopper => $c->stash->{'shopperid'},
            type    => CART_TYPE_TEMP
        }, RETURNAS_ITERATOR)->first;

        if (!$c->stash->{'cart'}) {
            $c->stash->{'cart'} = [% model %]->new({
                shopper => $c->stash->{'shopperid'},
                type    => CART_TYPE_TEMP
            });
        };
    };
};

sub end : Private {
    my ($self, $c) = @_;

    $c->forward('[% app %]::V::TT') unless $c->res->output;
};

sub default : Private {
    my ($self, $c) = @_;

    $c->forward('view');
};

sub view : Local {
    my ($self, $c) = @_;

    $c->stash->{'template'} = '[% uri %]/view.tt';
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

    $c->res->redirect($c->req->base . '[% uri %]/');
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

    $c->res->redirect($c->req->base . '[% uri %]/');
};

sub clear : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        $c->stash->{'cart'}->clear;
    };

    $c->res->redirect($c->req->base . '[% uri %]/');
};

sub delete : Local {
    my ($self, $c) = @_;
    my $id = $c->request->param('id');

    if ($id && $c->req->method eq 'POST') {
        $c->stash->{'cart'}->delete({
            id => $id
        });
    };

    $c->res->redirect($c->req->base . '[% uri %]/');
};

sub empty : Local {
    my ($self, $c) = @_;

    $c->forward('clear');
};

sub list : Local {
    my ($self, $c) = @_;

    $c->stash->{'carts'} = [% model %]->load({
        shopper => $c->stash->{'shopperid'},
        type    => CART_TYPE_SAVED
    }, RETURNAS_ITERATOR);

    $c->stash->{'template'} = '[% uri %]/list.tt';
};

sub save : Local {
    my ($self, $c) = @_;
    my $name = $c->req->param('name') || 'My Saved Cart';

    if ($c->req->method eq 'POST') {
        $c->stash->{'cart'}->name($name);
        $c->stash->{'cart'}->save;

        $c->res->redirect($c->req->base . '[% uri %]/list/');
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub restore : Local {
    my ($self, $c) = @_;
    my $id   = $c->req->param('id');
    my $mode = $c->req->param('mode') || CART_MODE_APPEND;

    if ($id && $c->req->method eq 'POST') {
        $c->stash->{'cart'}->restore({id => $id}, $mode);
    };

    $c->res->redirect($c->req->base . '[% uri %]/');
};

sub destroy : Local {
    my ($self, $c) = @_;
    my $id = $c->req->param('id');

    if ($id && $c->req->method eq 'POST') {
        [% model %]->destroy({
            id => $id
        });
    };

    $c->res->redirect($c->req->base . '[% uri %]/list/');
};
1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__view__
[% TAGS [- -] %]
<h1>Your Shopping Cart</h1>
<p>
    <a href="[% base _ '[- uri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/list/' %]">View Saved Carts</a>
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
            <form action="[% base _ '[- uri -]/update/' %]" method="post">
                <input type="hidden" name="id" value="[% item.id %]">
                <td align="left">[% item.sku %]</td>
                <td align="left">[% item.description %]</td>
                <td align="right">[% item.price.format(undef, 'FMT_SYMBOL') %]</td>
                <td align="center"><input style="text-align: center;" type="text" size="3" name="quantity" value="[% item.quantity %]"></td>
                <td align="right">[% item.total.format(undef, 'FMT_SYMBOL') %]</td>
                <td><input type="submit" value="Update"></td>
            </form>
            <form action="[% base _ '[- uri -]/delete/' %]" method="post">
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
                <form action="[% base _ '[- uri -]/empty/' %]" method="post">
                    <input type="submit" value="Empty Cart">
                </form>
                <form action="[% base %]checkout/" method="get">
                    <input type="submit" value="Checkout">
                </form>
            </td>
        </tr>
    </table>
    <form action="[% base _ '[- uri -]/save/' %]" method="post">
        <input type="text" name="name">
        <input type="submit" value="Save Cart">
    </form>
[% ELSE %]
    <p>Your shopping cart is empty.</p>
[% END %]
__list__
[% TAGS [- -] %]
<h1>Your Saved Shopping Carts</h1>
<p>
    <a href="[% base _ '[- uri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/list/' %]">View Saved Carts</a>
</p>
[% IF carts.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">Name</th>
            <th align="right">Restore Mode</th>
            <th></th>
        </tr>
    [% WHILE (cart = carts.next) %]
        <tr>
            <td align="left">[% cart.name %]</td>
            <td>
                <form action="[% base _ '[- uri -]/restore/' %]" method="POST">
                    <input type="hidden" name="id" value="[% cart.id %]">
                    <select name="mode">
                        [% USE hc = Handel.Constants %]
                        <option value="[% hc.CART_MODE_APPEND %]">Append</option>
                        <option value="[% hc.CART_MODE_MERGE %]">Merge</option>
                        <option value="[% hc.CART_MODE_REPLACE %]">Replace</option>
                    </select>
                    <input type="submit" value="Restore Cart">
                </form>
            </td>
            <td>
                <form action="[% base _ '[- uri -]/destroy/' %]" method="POST">
                    <input type="hidden" name="id" value="[% cart.id %]">
                    <input type="submit" value="Delete">
                </form>
            </td>
        </tr>
    [% END %]
    </table>
[% ELSE %]
    <p>You have no saved shopping carts.</p>
[% END %]
__END__

=head1 NAME

Catalyst::Helper::Controller::Handel::Cart - Helper for Handel::Cart Controllers

=head1 SYNOPSIS

    script/create.pl controller <newclass> Handel::Cart [<modelclass>]
    script/create.pl controller Cart       Handel::Cart Cart

=head1 DESCRIPTION

A Helper for creating controllers based on Handel::Cart objects. If no modelclass
is specified, ::M::Cart is assumed.

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Cart Controller class and template files for you.

=head2 mk_comptest

Makes a Handel::Cart Controller test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/