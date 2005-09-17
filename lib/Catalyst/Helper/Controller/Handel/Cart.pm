# $Id$
package Catalyst::Helper::Controller::Handel::Cart;
use strict;
use warnings;
use Path::Class;

sub mk_compclass {
    my ($self, $helper, $model, $checkout) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $helper->{'model'} = $model ? $helper->{'app'} . '::M::' . $model :
                         $helper->{'app'} . '::M::Cart';

    my $couri = $checkout =~ /^(.*::M(odel)?::)?(.*)$/i ? lc($3) : 'checkout';
    $couri =~ s/::/\//;
    $helper->{'couri'} = $couri;

    $helper->mk_dir($dir);
    #$helper->mk_component($helper->{'app'}, 'view', 'TT', 'TT');
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

our $DFV;

# Until this patch [hopefully] get's dumped into DFV 4.03, apply it and
# update FormValidator.pm verison to 4.03 to make this controller work with
# Data::FormValidator
#
#--- Results.pm.orig Wed Aug 31 22:27:27 2005
#+++ Results.pm  Wed Sep 14 17:40:28 2005
#@@ -584,7 +584,9 @@
#    if ($self->has_missing) {
#        my $missing = $self->missing;
#        for my $m (@$missing) {
#-           $msgs{$m} = _error_msg_fmt($profile{format},$profile{missing});
#+            $msgs{$m} = _error_msg_fmt($profile{format},
#+                (ref $profile{missing} eq 'HASH' ?
#+                    ($profile{missing}->{$m} || $profile{missing}->{default} || 'Missing') : $profile{missing}));
#        }
#    }

BEGIN {
    eval 'use Data::FormValidator 4.03';
    if (!$@) {
        $DFV = Data::FormValidator->new({
            cart_add => {
                required => [qw/sku quantity/],
                optional => [qw/price description/],
                field_filters => {
                    sku         => ['trim'],
                    quantity    => ['pos_integer'],
                    price       => ['pos_decimal'],
                    description => ['trim']
                },
                msgs => {
                    missing => {
                        default  => 'Field is blank!',
                        sku      => 'The SKU field is required',
                        quantity => 'The quantity field is required and must be a positive number'
                    },
                    format => '%s'
                }
            },
            cart_update => {
                required      => [qw/id quantity/],
                field_filters => {
                    id       => ['trim'],
                    quantity => ['pos_integer']
                },
                msgs => {
                    missing => {
                        default  => 'Field is blank!',
                        id       => 'The Id field is required for updating a cart item',
                        quantity => 'The quantity field is required and must be a positive number'
                    },
                    format => '%s'
                }
            },
            cart_delete => {
                required => ['id'],
                field_filters => {
                    id => ['trim']
                },
                msgs => {
                    missing => {
                        id => 'The Id field is required for delete a cart item'
                    },
                    format => '%s'
                }
            },
            cart_save => {
                required => [qw/name/],
                field_filters => {
                    name => ['trim']
                },
                msgs => {
                    missing => {
                        default => 'Field is blank',
                        name    => 'The Name field is required to save a cart'
                    },
                    format => '%s'
                }
            },
            cart_restore => {
                required => [qw/id mode/],
                field_filters => {
                    id   => ['trim'],
                    mode => ['digit']
                },
                msgs => {
                    missing => {
                        default => 'Field is blank',
                        id      => 'The id field is required for restoring saved cartds',
                        mode    => 'The mode field is required for restoring saved carts'
                    },
                    format => '%s'
                }
            },
            cart_destroy => {
                required => ['id'],
                field_filters => {
                    id => ['trim']
                },
                msgs => {
                    missing => {
                        id => 'The Id field is required for deleting saved carts'
                    },
                    format => '%s'
                }
            },
        });
    };
};

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
    my @messages;
    my $sku         = $c->request->param('sku');
    my $quantity    = $c->request->param('quantity');
    my $price       = $c->request->param('price');
    my $description = $c->request->param('description');

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_add');
        };

        if ($results || !$DFV) {
            if ($results) {
                $sku         = $results->valid('sku');
                $quantity    = $results->valid('quantity');
                $price       = $results->valid('price');
                $description = $results->valid('description');
            };

            $quantity ||= 1;

            eval {
                $c->stash->{'cart'}->add({
                    sku         => $sku,
                    quantity    => $quantity,
                    price       => $price,
                    description => $description
                });
            };
            if ($@) {
                push @messages, $@;
            };
        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'template'} = '[% uri %]/view.tt';
        $c->stash->{'messages'} = \@messages;
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub update : Local {
    my ($self, $c) = @_;
    my @messages;
    my $id       = $c->request->param('id');
    my $quantity = $c->request->param('quantity');

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_update');
        };

        if ($results || !$DFV) {
            if ($results) {
                $id       = $results->valid('id');
                $quantity = $results->valid('quantity');
            };

            $quantity ||= 1;

            my $item = $c->stash->{'cart'}->items({
                id => $id
            });

            eval {
                if ($item) {
                    $item->quantity($quantity);
                };
            };
            if ($@) {
                push @messages, $@;
            };

            undef $item;
        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'template'} = '[% uri %]/view.tt';
        $c->stash->{'messages'} = \@messages;
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub clear : Local {
    my ($self, $c) = @_;
    my @messages;

    if ($c->req->method eq 'POST') {
        eval {
            $c->stash->{'cart'}->clear;
        };
        if ($@) {
            push @messages, $@;
        };
    };

    if (scalar @messages) {
        $c->stash->{'template'} = '[% uri %]/view.tt';
        $c->stash->{'messages'} = \@messages;
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub delete : Local {
    my ($self, $c) = @_;
    my @messages;
    my $id = $c->request->param('id');

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_delete');
        };

        if ($results || !$DFV) {
            if ($results) {
                $id       = $results->valid('id');
            };

            eval {
                $c->stash->{'cart'}->delete({
                    id => $id
                });
            };
            if ($@) {
                push @messages, $@;
            };
        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'template'} = '[% uri %]/view.tt';
        $c->stash->{'messages'} = \@messages;
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub empty : Local {
    my ($self, $c) = @_;

    $c->forward('clear');
};

sub list : Local {
    my ($self, $c) = @_;
    my @messages;

    eval {
        $c->stash->{'carts'} = MyApp::M::Cart->load({
            shopper => $c->stash->{'shopperid'},
            type    => CART_TYPE_SAVED
        }, RETURNAS_ITERATOR);
    };
    if ($@) {
        push @messages, $@;

        $c->stash->{'messages'} = \@messages;
    };

    $c->stash->{'template'} = '[% uri %]/list.tt';
};

sub save : Local {
    my ($self, $c) = @_;
    my @messages;
    my $name = $c->req->param('name');

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_save');
        };

        if ($results || !$DFV) {
            if ($results) {
                $name = $results->valid('name');
            };

            eval {
                $c->stash->{'cart'}->name($name);
                $c->stash->{'cart'}->save;
            };
            if ($@) {
                push @messages, $@;
            };

        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'template'} = '[% uri %]/view.tt';
        $c->stash->{'messages'} = \@messages;
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub restore : Local {
    my ($self, $c) = @_;
    my @messages;
    my $id   = $c->req->param('id');
    my $mode = $c->req->param('mode') || CART_MODE_APPEND;

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_restore');
        };

        if ($results || !$DFV) {
            if ($results) {
                $id   = $results->valid('id');
                $mode = $results->valid('mode');
            };

            eval {
                $c->stash->{'cart'}->restore({id => $id}, $mode);
            };
            if ($@) {
                push @messages, $@;
            };

            $c->res->redirect($c->req->base . '[% uri %]/');
        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'messages'} = \@messages;
        $c->forward('list');
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/');
    };
};

sub destroy : Local {
    my ($self, $c) = @_;
    my @messages;
    my $id = $c->req->param('id');

    if ($c->req->method eq 'POST') {
        my $results;

        if ($DFV) {
            $results = $DFV->check($c->req->parameters, 'cart_destroy');
        };

        if ($results || !$DFV) {
            if ($results) {
                $id   = $results->valid('id');
            };

            eval {
                MyApp::M::Cart->destroy({
                    id => $id
                });
            };
            if ($@) {
                push @messages, $@;
            };
        } else {
            push @messages, map {$_} values %{$results->msgs};
        };
    };

    if (scalar @messages) {
        $c->stash->{'messages'} = \@messages;
        $c->forward('list');
    } else {
        $c->res->redirect($c->req->base . '[% uri %]/list/');
    };
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
[% USE HTML %]
<h1>Your Shopping Cart</h1>
<p>
    <a href="[% base _ '[- uri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/list/' %]">View Saved Carts</a>
</p>
[% IF messages %]
    <ul>
        [% FOREACH message IN messages %]
            <li>[% message %]</li>
        [% END %]
    </ul>
[% END %]
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
                <input type="hidden" name="id" value="[% HTML.escape(item.id) %]">
                <td align="left">[% HTML.escape(item.sku) %]</td>
                <td align="left">[% HTML.escape(item.description) %]</td>
                <td align="right">[% HTML.escape(item.price.format(undef, 'FMT_SYMBOL')) %]</td>
                <td align="center"><input style="text-align: center;" type="text" size="3" name="quantity" value="[% HTML.escape(item.quantity) %]"></td>
                <td align="right">[% HTML.escape(item.total.format(undef, 'FMT_SYMBOL')) %]</td>
                <td><input type="submit" value="Update"></td>
            </form>
            <form action="[% base _ '[- uri -]/delete/' %]" method="post">
                <input type="hidden" name="id" value="[% HTML.escape(item.id) %]">
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
            <td align="right">[% HTML.escape(cart.subtotal.format(undef, 'FMT_SYMBOL')) %]</td>
            <td colspan="2"></td>
        </tr>
        <tr>
            <td colspan="7" align="right">
                <form action="[% base _ '[- uri -]/empty/' %]" method="post">
                    <input type="submit" value="Empty Cart">
                </form>
                <form action="[% base  _ '[- couri -]/' %]" method="get">
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
[% USE HTML %]
<h1>Your Saved Shopping Carts</h1>
<p>
    <a href="[% base _ '[- uri -]/' %]">View Cart</a> |
    <a href="[% base _ '[- uri -]/list/' %]">View Saved Carts</a>
</p>
[% IF messages %]
    <ul>
        [% FOREACH message IN messages %]
            <li>[% message %]</li>
        [% END %]
    </ul>
[% END %]
[% IF carts.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">Name</th>
            <th align="right">Restore Mode</th>
            <th></th>
        </tr>
    [% WHILE (cart = carts.next) %]
        <tr>
            <td align="left" valign="top">[% HTML.escape(cart.name) %]</td>
            <td>
                <form action="[% base _ '[- uri -]/restore/' %]" method="POST">
                    <input type="hidden" name="id" value="[% HTML.escape(cart.id) %]">
                    <select name="mode">
                        [% USE hc = Handel.Constants %]
                        <option value="[% HTML.escape(hc.CART_MODE_APPEND) %]">Append</option>
                        <option value="[% HTML.escape(hc.CART_MODE_MERGE) %]">Merge</option>
                        <option value="[% HTML.escape(hc.CART_MODE_REPLACE) %]">Replace</option>
                    </select>
                    <input type="submit" value="Restore Cart">
                </form>
            </td>
            <td>
                <form action="[% base _ '[- uri -]/destroy/' %]" method="POST">
                    <input type="hidden" name="id" value="[% HTML.escape(cart.id) %]">
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

    script/create.pl controller <newclass> Handel::Cart [<modelclass> <checkoutcontroller>]
    script/create.pl controller Cart       Handel::Cart Cart Checkout

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