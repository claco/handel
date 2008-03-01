# $Id$
package Catalyst::Helper::Handel;
use strict;
use warnings;

BEGIN {
    use base qw/Catalyst::Helper::Handel::Scaffold/;
    use Config;
    use Catalyst::Utils;
    use Module::Starter::Handel;
    use File::Spec::Functions qw/catfile catdir/;
};


sub mk_stuff {
    my $self = shift;
    my $helper = $_[0];
    my $starter = 'Module::Starter::Handel';
    my $t = Template->new;
    my $app = $helper->{'app'};
    my $base = $app;
       $base =~ s/::/\//g;
    my $path = catdir($helper->{'base'}, 'lib', $base);
    my $contents;


    $helper->mk_dir(catdir($helper->{'base'}, 'data'));

    foreach my $class (qw/Cart Cart::Item Storage::Cart Storage::Cart::Item Order Order::Item Storage::Order Storage::Order::Item Checkout/) {
        my $template = $starter->_get_file($class);
        my @parts = split(/::/, $class);
        my $filepath = $path;
        my $contents;

        if (scalar @parts > 1) {
            for (0..$#parts-1) {
                $filepath = catdir($filepath, $parts[$_]);
            };
        };

        $helper->mk_dir($filepath);
        $parts[-1] = $parts[-1] . '.pm';
        
        $t->process(\$template, {%{$helper}, module => "$app\:\:$class"}, \$contents);
        
        $helper->mk_file(catfile($path, @parts), $contents);
    };

    my $template = $starter->_get_file('setup');
    $helper->{'startperl'} = "#!$Config{perlpath} -w";
    $helper->{'scriptname'} = Catalyst::Utils::appprefix($app) . '_handel.pl';
    $t->process(\$template, {%{$helper}}, \$contents);

    my $setup = catfile($helper->{'base'}, 'script', Catalyst::Utils::appprefix($app) . '_handel.pl');
    $helper->mk_file($setup, $contents);
    chmod oct 700, $setup;

    $helper->{'handel_auto_wire_models'} = 1;
    $self->SUPER::mk_stuff(@_);

    warn "\n\aDon't forget to add Session, Session::Store::File and Session::State::Cookie to $base.pm!\n";

    return;
};

1;
__END__

=head1 NAME

Catalyst::Helper::Handel - Helper for creating a Handel based application

=head1 SYNOPSIS

    script/create.pl Handel <dsn> [<username> <password> <cartname> <ordername> <checkoutname>]
    script/create.pl Handel dbi:SQLite:dbname=handel.db

=head1 DESCRIPTION

The Handel helper is a meta Helper for creating the entire cart/order/checkout
framework plus custom subclasses using the other helpers included in this dist
and Module::Starter::Handel.

If cartname isn't specified, Cart is assumed. If ordername isn't specified,
Orders is assumed. If no checkoutname is given, Checkout is assumed.

The cartname, ordername, and checkoutname arguments try to do the right thing
with the names given to them.

For example, you can pass the shortened class name without the MyApp::M/C, or
pass the fully qualified package name:

    MyApp::M::CartModel
    MyApp::Model::CartModel
    CartModel

In all three cases everything before M{odel)|C(ontroller) will be stripped and
the class CartModel will be used.

=head1 METHODS

=head2 mk_stuff

Makes Cart and Order models, Cart, Order and Checkout controllers, templates
files, custom Cart, Order, Checkout, Storage classes, and a TT view for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Module::Starter::Handel>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
