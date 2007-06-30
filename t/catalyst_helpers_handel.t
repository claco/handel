#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Cwd;
    use File::Path;
    use File::Spec::Functions;

    eval 'use Catalyst 5.7001';
    plan(skip_all =>
        'Catalyst 5.7001 not installed') if $@;

    eval 'use Catalyst::Devel 1.0';
    plan(skip_all =>
        'Catalyst::Devel 1.0 not installed') if $@;

    eval 'use Catalyst::View::TT';
    plan(skip_all =>
        'Catalyst::View::TT not installed') if $@;

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    plan tests => 44;

    use_ok('Catalyst::Helper');
    use_ok('Catalyst::Helper::Handel');
    use_ok('Catalyst::Helper::Model::Handel::Cart');
    use_ok('Catalyst::Model::Handel::Cart');
    use_ok('Catalyst::Helper::Model::Handel::Order');
    use_ok('Catalyst::Model::Handel::Order');
    use_ok('Catalyst::Helper::Controller::Handel::Cart');
    use_ok('Catalyst::Helper::Controller::Handel::Order');
    use_ok('Catalyst::Helper::Controller::Handel::Checkout');
};

my $helper = Catalyst::Helper->new;
my $app = 'TestApp';


## setup var
chdir('t');
mkdir('var') unless -d 'var';
chdir('var');


## create test app
{
    rmtree($app);
    $helper->mk_app($app);
    $FindBin::Bin = catdir(cwd, $app, 'lib');
};


## create the defaults
{
    my $cmodel = catfile($app, 'lib', $app, 'Model', 'Cart.pm');
    my $omodel = catfile($app, 'lib', $app, 'Model', 'Order.pm');

    my $cmodule   = catfile($app, 'lib', $app, 'Controller', 'Cart.pm');
    my $clist     = catfile($app, 'root', 'cart', 'list');
    my $cview     = catfile($app, 'root', 'cart', 'default');
    my $cmessages = catfile($app, 'root', 'cart', 'messages.yml');
    my $cprofiles = catfile($app, 'root', 'cart', 'profiles.yml');

    my $omodule   = catfile($app, 'lib', $app, 'Controller', 'Order.pm');
    my $olist     = catfile($app, 'root', 'order', 'default');
    my $oview     = catfile($app, 'root', 'order', 'view');
    my $omessages = catfile($app, 'root', 'order', 'messages.yml');
    my $oprofiles = catfile($app, 'root', 'order', 'profiles.yml');

    my $comodule   = catfile($app, 'lib', $app, 'Controller', 'Checkout.pm');
    my $coedit     = catfile($app, 'root', 'checkout', 'billing');
    my $copreview  = catfile($app, 'root', 'checkout', 'preview');
    my $copayment  = catfile($app, 'root', 'checkout', 'payment');
    my $cocomplete = catfile($app, 'root', 'checkout', 'complete');
    my $comessages = catfile($app, 'root', 'checkout', 'messages.yml');
    my $coprofiles = catfile($app, 'root', 'checkout', 'profiles.yml');

    my $cart             = catfile($app, 'lib', $app, 'Cart.pm');
    my $cartitem         = catfile($app, 'lib', $app, 'Cart', 'Item.pm');
    my $cartstorage      = catfile($app, 'lib', $app, 'Storage', 'Cart.pm');
    my $cartitemstorage  = catfile($app, 'lib', $app, 'Storage', 'Cart', 'Item.pm');
    my $order            = catfile($app, 'lib', $app, 'Order.pm');
    my $orderitem        = catfile($app, 'lib', $app, 'Order', 'Item.pm');
    my $orderstorage     = catfile($app, 'lib', $app, 'Storage', 'Order.pm');
    my $orderitemstorage = catfile($app, 'lib', $app, 'Storage', 'Order', 'Item.pm');
    my $checkout         = catfile($app, 'lib', $app, 'Checkout.pm');
    my $setup            = catfile($app, 'script', 'testapp_handel.pl');

    $helper->mk_component($app, 'Handel', 'sdsn', 'suser', 'spass');
    file_exists_ok($cmodel);
    file_exists_ok($omodel);

    file_exists_ok($cmodule);
    file_exists_ok($clist);
    file_exists_ok($cview);
    file_exists_ok($cmessages);
    file_exists_ok($cprofiles);

    file_exists_ok($omodule);
    file_exists_ok($olist);
    file_exists_ok($oview);
    file_exists_ok($omessages);
    file_exists_ok($oprofiles);

    file_exists_ok($comodule);
    file_exists_ok($coedit);
    file_exists_ok($copreview);
    file_exists_ok($copayment);
    file_exists_ok($cocomplete);
    file_exists_ok($comessages);
    file_exists_ok($coprofiles);

    file_exists_ok($cart);
    file_exists_ok($cartitem);
    file_exists_ok($cartstorage);
    file_exists_ok($cartitemstorage);
    file_exists_ok($order);
    file_exists_ok($orderitem);
    file_exists_ok($orderstorage);
    file_exists_ok($orderitemstorage);
    file_exists_ok($checkout);
    file_exists_ok($setup);

    file_contents_like($cmodel, qr/cart_class => 'TestApp::Cart'/);
    file_contents_like($omodel, qr/order_class => 'TestApp::Order'/);
    file_contents_like($setup,  qr/use TestApp::Storage::Cart/);
    file_contents_like($setup,  qr/use TestApp::Storage::Order/);
    file_contents_like($setup,  qr/TestApp::Storage::Cart->new/);
    file_contents_like($setup,  qr/TestApp::Storage::Order->new/);
};
