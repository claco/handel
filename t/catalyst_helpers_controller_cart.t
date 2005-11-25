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

    plan tests => 101;

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


## create the default cart controller
{
    my $module = catfile($app, 'lib', $app, 'C', 'Cart.pm');
    my $list   = catfile($app, 'root', 'cart', 'list.tt');
    my $view   = catfile($app, 'root', 'cart', 'view.tt');

    $helper->mk_component($app, 'controller', 'Cart', 'Handel::Cart');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Cart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'cart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'cart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'cart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'cart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a two part default cart controller
{
    my $module = catfile($app, 'lib', $app, 'C', 'My', 'Cart.pm');
    my $list   = catfile($app, 'root', 'my', 'cart', 'list.tt');
    my $view   = catfile($app, 'root', 'my', 'cart', 'view.tt');

    $helper->mk_component($app, 'controller', 'My::Cart', 'Handel::Cart');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Cart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'my\/cart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'my\/cart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'my\/cart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a controller with a non-default model class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyCart.pm');
    my $list   = catfile($app, 'root', 'mycart', 'list.tt');
    my $view   = catfile($app, 'root', 'mycart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyCart', 'Handel::Cart', 'MyCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCartModel'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'mycart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a controller with a non-default two part model class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyOtherCart.pm');
    my $list   = catfile($app, 'root', 'myothercart', 'list.tt');
    my $view   = catfile($app, 'root', 'myothercart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyOtherCart', 'Handel::Cart', 'My::Cart::Model');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::Cart::Model'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myothercart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myothercart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'myothercart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a controller with a non-default fully qualified model class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyNewCart.pm');
    my $list   = catfile($app, 'root', 'mynewcart', 'list.tt');
    my $view   = catfile($app, 'root', 'mynewcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyNewCart', 'Handel::Cart', 'TestApp::M::MyNewCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyNewCartModel'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mynewcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mynewcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'mynewcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a controller with a non-default fully qualified model class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyThirdCart.pm');
    my $list   = catfile($app, 'root', 'mythirdcart', 'list.tt');
    my $view   = catfile($app, 'root', 'mythirdcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyThirdCart', 'Handel::Cart', 'TestApp::Model::MyNewCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyNewCartModel'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mythirdcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mythirdcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'mythirdcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'checkout\/' %\]/);
};


## create a controller with a non-default checkout class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyCustomCart.pm');
    my $list   = catfile($app, 'root', 'mycustomcart', 'list.tt');
    my $view   = catfile($app, 'root', 'mycustomcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyCustomCart', 'Handel::Cart', 'MyCart', 'MyCheckout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycustomcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycustomcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycustomcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mycustomcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'mycustomcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'mycheckout\/' %\]/);
};


## create a controller with a two part checkout class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyBestCart.pm');
    my $list   = catfile($app, 'root', 'mybestcart', 'list.tt');
    my $view   = catfile($app, 'root', 'mybestcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyBestCart', 'Handel::Cart', 'MyCart', 'My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mybestcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mybestcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mybestcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'mybestcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'mybestcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'my\/checkout\/' %\]/);
};


## create a controller with a fully qualified checkout class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyWorstCart.pm');
    my $list   = catfile($app, 'root', 'myworstcart', 'list.tt');
    my $view   = catfile($app, 'root', 'myworstcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyWorstCart', 'Handel::Cart', 'MyCart', 'TestApp::C::My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myworstcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myworstcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myworstcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myworstcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'myworstcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'my\/checkout\/' %\]/);
};


## create a controller with a fully qualified checkout class name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyFQCart.pm');
    my $list   = catfile($app, 'root', 'myfqcart', 'list.tt');
    my $view   = catfile($app, 'root', 'myfqcart', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyFQCart', 'Handel::Cart', 'MyCart', 'TestApp::Controller::My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myfqcart\/view.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myfqcart\/'\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myfqcart\/list.tt';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->req->base . 'myfqcart\/list\/'\);/);
    file_contents_like($view, qr/\[% base _ 'myfqcart\/list\/' %\]/);
    file_contents_like($view, qr/\[% base  _ 'my\/checkout\/' %\]/);
};
