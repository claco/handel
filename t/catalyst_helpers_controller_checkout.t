#!perl -w
# $Id$
use strict;
use warnings;
use Test::More;
use Cwd;
use File::Path;
use File::Spec::Functions;

BEGIN {
    eval 'use Catalyst 5.00';
    plan(skip_all =>
        'Catalyst 5 not installed') if $@;

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    plan tests => 91;

    use_ok('Catalyst::Helper');
};

my $helper = Catalyst::Helper->new({short => 1});
my $app = 'TestApp';


## create test app
{
    chdir('t');
    rmtree('TestApp');
    $helper->mk_app($app);
    $FindBin::Bin = catdir(cwd, $app, 'lib');
};


## create the default checkout controller
{
    my $module   = catfile($app, 'lib', $app, 'C', 'Checkout.pm');
    my $edit     = catfile($app, 'root', 'checkout', 'edit.tt');
    my $preview  = catfile($app, 'root', 'checkout', 'preview.tt');
    my $payment  = catfile($app, 'root', 'checkout', 'payment.tt');
    my $complete = catfile($app, 'root', 'checkout', 'complete.tt');

    $helper->mk_component($app, 'controller', 'Checkout', 'Handel::Checkout');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->model\('Cart'\)->load/);
    file_contents_like($module, qr/->model\('Orders'\)->load/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/edit.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'checkout\/preview\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/payment.tt';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/complete.tt';/);
    file_contents_like($edit, qr/\[% base _ 'cart\/' %\]/);
    file_contents_like($edit, qr/\[% base _ 'checkout\/update\/' %\]/);
    file_contents_like($preview, qr/\[% base _ 'checkout\/edit\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'checkout\/preview\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'checkout\/payment\/' %\]/);
    file_contents_like($complete, qr/\[% base _ 'orders\/list\/' %\]/);
};


## create the checkout controller with custom model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'C', 'MyCheckout.pm');
    my $edit     = catfile($app, 'root', 'mycheckout', 'edit.tt');
    my $preview  = catfile($app, 'root', 'mycheckout', 'preview.tt');
    my $payment  = catfile($app, 'root', 'mycheckout', 'payment.tt');
    my $complete = catfile($app, 'root', 'mycheckout', 'complete.tt');

    $helper->mk_component($app, 'controller', 'MyCheckout', 'Handel::Checkout', 'MyCartModel', 'MyOrdersModel', 'MyCart', 'MyOrders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->model\('MyCartModel'\)->load/);
    file_contents_like($module, qr/->model\('MyOrdersModel'\)->load/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/edit.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycheckout\/preview\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/payment.tt';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/complete.tt';/);
    file_contents_like($edit, qr/\[% base _ 'mycart\/' %\]/);
    file_contents_like($edit, qr/\[% base _ 'mycheckout\/update\/' %\]/);
    file_contents_like($preview, qr/\[% base _ 'mycheckout\/edit\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mycheckout\/preview\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mycheckout\/payment\/' %\]/);
    file_contents_like($complete, qr/\[% base _ 'myorders\/list\/' %\]/);
};


## create the checkout controller with custom two part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'C', 'MyNewCheckout.pm');
    my $edit     = catfile($app, 'root', 'mynewcheckout', 'edit.tt');
    my $preview  = catfile($app, 'root', 'mynewcheckout', 'preview.tt');
    my $payment  = catfile($app, 'root', 'mynewcheckout', 'payment.tt');
    my $complete = catfile($app, 'root', 'mynewcheckout', 'complete.tt');

    $helper->mk_component($app, 'controller', 'MyNewCheckout', 'Handel::Checkout', 'My::CartModel', 'My::OrdersModel', 'My::Cart', 'My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->model\('My::CartModel'\)->load/);
    file_contents_like($module, qr/->model\('My::OrdersModel'\)->load/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'my\/cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/edit.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mynewcheckout\/preview\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/payment.tt';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/complete.tt';/);
    file_contents_like($edit, qr/\[% base _ 'my\/cart\/' %\]/);
    file_contents_like($edit, qr/\[% base _ 'mynewcheckout\/update\/' %\]/);
    file_contents_like($preview, qr/\[% base _ 'mynewcheckout\/edit\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mynewcheckout\/preview\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mynewcheckout\/payment\/' %\]/);
    file_contents_like($complete, qr/\[% base _ 'my\/orders\/list\/' %\]/);
};


## create the checkout controller with custom fully qualified part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'C', 'MyOtherCheckout.pm');
    my $edit     = catfile($app, 'root', 'myothercheckout', 'edit.tt');
    my $preview  = catfile($app, 'root', 'myothercheckout', 'preview.tt');
    my $payment  = catfile($app, 'root', 'myothercheckout', 'payment.tt');
    my $complete = catfile($app, 'root', 'myothercheckout', 'complete.tt');

    $helper->mk_component($app, 'controller', 'MyOtherCheckout', 'Handel::Checkout', 'TestApp::M::My::CartModel', 'TestApp::M::My::OrdersModel', 'TestApp::C::My::Cart', 'TestApp::C::My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->model\('My::CartModel'\)->load/);
    file_contents_like($module, qr/->model\('My::OrdersModel'\)->load/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'my\/cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/edit.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myothercheckout\/preview\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/payment.tt';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/complete.tt';/);
    file_contents_like($edit, qr/\[% base _ 'my\/cart\/' %\]/);
    file_contents_like($edit, qr/\[% base _ 'myothercheckout\/update\/' %\]/);
    file_contents_like($preview, qr/\[% base _ 'myothercheckout\/edit\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'myothercheckout\/preview\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'myothercheckout\/payment\/' %\]/);
    file_contents_like($complete, qr/\[% base _ 'my\/orders\/list\/' %\]/);
};


## create the checkout controller with custom fully qualified part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'C', 'MyThirdCheckout.pm');
    my $edit     = catfile($app, 'root', 'mythirdcheckout', 'edit.tt');
    my $preview  = catfile($app, 'root', 'mythirdcheckout', 'preview.tt');
    my $payment  = catfile($app, 'root', 'mythirdcheckout', 'payment.tt');
    my $complete = catfile($app, 'root', 'mythirdcheckout', 'complete.tt');

    $helper->mk_component($app, 'controller', 'MyThirdCheckout', 'Handel::Checkout', 'TestApp::Model::My::CartModel', 'TestApp::Model::My::OrdersModel', 'TestApp::Controller::My::Cart', 'TestApp::Controller::My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->model\('My::CartModel'\)->load/);
    file_contents_like($module, qr/->model\('My::OrdersModel'\)->load/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'my\/cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/edit.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mythirdcheckout\/preview\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/payment.tt';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/complete.tt';/);
    file_contents_like($edit, qr/\[% base _ 'my\/cart\/' %\]/);
    file_contents_like($edit, qr/\[% base _ 'mythirdcheckout\/update\/' %\]/);
    file_contents_like($preview, qr/\[% base _ 'mythirdcheckout\/edit\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mythirdcheckout\/preview\/' %\]/);
    file_contents_like($payment, qr/\[% base _ 'mythirdcheckout\/payment\/' %\]/);
    file_contents_like($complete, qr/\[% base _ 'my\/orders\/list\/' %\]/);
};
