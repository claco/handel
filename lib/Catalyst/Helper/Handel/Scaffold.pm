# $Id$
package Catalyst::Helper::Handel::Scaffold;
use strict;
use warnings;
use Path::Class;
use File::Find::Rule;

sub mk_stuff {
    my ($self, $helper, $dsn, $user, $pass, $cart, $order, $checkout) = @_;

    $cart     ||= 'Cart';
    $order    ||= 'Orders';
    $checkout ||= 'Checkout';

    my $app = $helper->{'app'};

    $helper->mk_component($app, 'view', 'TT', 'TT');
    $helper->mk_component($app, 'model', $cart, 'Handel::Cart', $dsn, $user, $pass);
    $helper->mk_component($app, 'model', $order, 'Handel::Order', $dsn, $user, $pass);
    $helper->mk_component($app, 'controller', $cart, 'Handel::Cart', $cart, $checkout);
    $helper->mk_component($app, 'controller', $order, 'Handel::Order', $order);
    $helper->mk_component($app, 'controller', $checkout, 'Handel::Checkout', $cart, $order);
};

1;
__END__

=head1 NAME

Catalyst::Helper::Handel::Scaffold - Helper for create Handel frameework scaffolding

=head1 SYNOPSIS

    script/create.pl Handel::Scaffold <dsn> [<username> <password> <cartname> <ordername> <checkoutname>]
    script/create.pl Handel::Scaffold dbi:SQLite:dbname=handel.db

=head1 DESCRIPTION

A Helper for creating an entire cart/order/checkout framework scaffold.
If cartname isn't specified, Cart is assumed. If ordername isn't specified,
Orders is assumed. If no checkoutname is given, Checkout is assumed.

=head1 METHODS

=head2 mk_stuff

Makes Cart and Order models, Cart, Order and Checkout controllers, templates files
and a TT view for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/