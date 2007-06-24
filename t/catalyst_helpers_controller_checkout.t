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

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    plan tests => 94;

    use_ok('Catalyst::Helper');
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


## create the default checkout controller
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'Checkout.pm');
    my $edit     = catfile($app, 'root', 'checkout', 'billing');
    my $preview  = catfile($app, 'root', 'checkout', 'preview');
    my $payment  = catfile($app, 'root', 'checkout', 'payment');
    my $complete = catfile($app, 'root', 'checkout', 'complete');
    my $messages = catfile($app, 'root', 'checkout', 'messages.yml');
    my $profiles = catfile($app, 'root', 'checkout', 'profiles.yml');

    $helper->mk_component($app, 'controller', 'Checkout', 'Handel::Checkout');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);
    file_exists_ok($messages);
    file_exists_ok($profiles);
    file_contents_like($module, qr/->controller\('Cart'\)/);
    file_contents_like($module, qr/->controller\('Order'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/checkout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/checkout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/checkout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/checkout\/payment\/'\) %\]/);
    file_contents_like($messages, qr/^checkout\/view:/);
    file_contents_like($profiles, qr/^checkout\/view:/);
};


## load it up
SKIP: {
    eval 'require HTML::FillInForm';
    skip 'HTML::FillInForm not installed', 1 if $@;

    my $lib = catfile(cwd, $app, 'lib');
    eval "use lib '$lib';use $app\:\:Controller\:\:Checkout";
    ok(!$@, 'loaded new class');
};


## create the checkout controller with custom model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'MyCheckout.pm');
    my $edit     = catfile($app, 'root', 'mycheckout', 'billing');
    my $preview  = catfile($app, 'root', 'mycheckout', 'preview');
    my $payment  = catfile($app, 'root', 'mycheckout', 'payment');
    my $complete = catfile($app, 'root', 'mycheckout', 'complete');

    $helper->mk_component($app, 'controller', 'MyCheckout', 'Handel::Checkout', 'MyCartModel', 'MyOrdersModel', 'MyCart', 'MyOrders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->controller\('MyCart'\)/);
    file_contents_like($module, qr/->controller\('MyOrders'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mycheckout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycheckout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/mycheckout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/mycheckout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/mycheckout\/payment\/'\) %\]/);
};


## create the checkout controller with custom two part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'MyNewCheckout.pm');
    my $edit     = catfile($app, 'root', 'mynewcheckout', 'billing');
    my $preview  = catfile($app, 'root', 'mynewcheckout', 'preview');
    my $payment  = catfile($app, 'root', 'mynewcheckout', 'payment');
    my $complete = catfile($app, 'root', 'mynewcheckout', 'complete');

    $helper->mk_component($app, 'controller', 'MyNewCheckout', 'Handel::Checkout', 'My::CartModel', 'My::OrdersModel', 'My::Cart', 'My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->controller\('My::Cart'\)/);
    file_contents_like($module, qr/->controller\('My::Orders'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mynewcheckout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcheckout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/mynewcheckout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/mynewcheckout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/mynewcheckout\/payment\/'\) %\]/);
};


## create the checkout controller with custom fully qualified part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'MyOtherCheckout.pm');
    my $edit     = catfile($app, 'root', 'myothercheckout', 'billing');
    my $preview  = catfile($app, 'root', 'myothercheckout', 'preview');
    my $payment  = catfile($app, 'root', 'myothercheckout', 'payment');
    my $complete = catfile($app, 'root', 'myothercheckout', 'complete');

    $helper->mk_component($app, 'controller', 'MyOtherCheckout', 'Handel::Checkout', 'TestApp::M::My::CartModel', 'TestApp::M::My::OrdersModel', 'TestApp::C::My::Cart', 'TestApp::C::My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->controller\('My::Cart'\)/);
    file_contents_like($module, qr/->controller\('My::Orders'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myothercheckout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercheckout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/myothercheckout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/myothercheckout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/myothercheckout\/payment\/'\) %\]/);
};


## create the checkout controller with custom fully qualified part model/controller args
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'MyThirdCheckout.pm');
    my $edit     = catfile($app, 'root', 'mythirdcheckout', 'billing');
    my $preview  = catfile($app, 'root', 'mythirdcheckout', 'preview');
    my $payment  = catfile($app, 'root', 'mythirdcheckout', 'payment');
    my $complete = catfile($app, 'root', 'mythirdcheckout', 'complete');

    $helper->mk_component($app, 'controller', 'MyThirdCheckout', 'Handel::Checkout', 'TestApp::Model::My::CartModel', 'TestApp::Model::My::OrdersModel', 'TestApp::Controller::My::Cart', 'TestApp::Controller::My::Orders');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);

    file_contents_like($module, qr/->controller\('My::Cart'\)/);
    file_contents_like($module, qr/->controller\('My::Orders'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mythirdcheckout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcheckout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/mythirdcheckout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/mythirdcheckout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/mythirdcheckout\/payment\/'\) %\]/);
};


## create the default checkout controller with bogus controller/models
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'Checkout.pm');
    my $edit     = catfile($app, 'root', 'checkout', 'billing');
    my $preview  = catfile($app, 'root', 'checkout', 'preview');
    my $payment  = catfile($app, 'root', 'checkout', 'payment');
    my $complete = catfile($app, 'root', 'checkout', 'complete');
    my $messages = catfile($app, 'root', 'checkout', 'messages.yml');
    my $profiles = catfile($app, 'root', 'checkout', 'profiles.yml');

    unlink $module;
    unlink $edit;
    unlink $preview;
    unlink $payment;
    unlink $complete;
    unlink $messages;
    unlink $profiles;

    $helper->mk_component($app, 'controller', 'Checkout', 'Handel::Checkout', 'TestApp::Model::', 'TestApp::Model::', 'TestApp::Controller::', 'TestApp::Controller::');
    file_exists_ok($module);
    file_exists_ok($edit);
    file_exists_ok($preview);
    file_exists_ok($payment);
    file_exists_ok($complete);
    file_exists_ok($messages);
    file_exists_ok($profiles);
    file_contents_like($module, qr/->controller\('Cart'\)/);
    file_contents_like($module, qr/->controller\('Order'\)/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/checkout\/'\)/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/billing';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/payment';/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'checkout\/complete';/);
    file_contents_like($edit, qr/\[% c.uri_for\('\/checkout\/billing\/'\) %\]/);
    file_contents_like($preview, qr/\[% c.uri_for\('\/checkout\/payment\/'\) %\]/);
    file_contents_like($payment, qr/\[% c.uri_for\('\/checkout\/payment\/'\) %\]/);
    file_contents_like($messages, qr/^checkout\/view:/);
    file_contents_like($profiles, qr/^checkout\/view:/);
};
