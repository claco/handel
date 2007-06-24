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

    plan tests => 126;

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


## create the default cart controller
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'Cart.pm');
    my $list     = catfile($app, 'root', 'cart', 'list');
    my $view     = catfile($app, 'root', 'cart', 'default');
    my $messages = catfile($app, 'root', 'cart', 'messages.yml');
    my $profiles = catfile($app, 'root', 'cart', 'profiles.yml');

    $helper->mk_component($app, 'controller', 'Cart', 'Handel::Cart');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_exists_ok($messages);
    file_exists_ok($profiles);
    file_contents_like($module, qr/->model\('Cart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'cart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/cart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'cart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/cart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/cart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
    file_contents_like($messages, qr/^cart\/save:/);
    file_contents_like($profiles, qr/^cart\/save:/);
};


## load it up
{
    my $lib = catfile(cwd, $app, 'lib');
    eval "use lib '$lib';use $app\:\:Controller\:\:Cart";
    ok(!$@, 'loaded new class');
};


## create a two part default cart controller
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'My', 'Cart.pm');
    my $list   = catfile($app, 'root', 'my', 'cart', 'list');
    my $view   = catfile($app, 'root', 'my', 'cart', 'default');

    $helper->mk_component($app, 'controller', 'My::Cart', 'Handel::Cart');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Cart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/cart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a non-default model class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyCart.pm');
    my $list   = catfile($app, 'root', 'mycart', 'list');
    my $view   = catfile($app, 'root', 'mycart', 'default');

    $helper->mk_component($app, 'controller', 'MyCart', 'Handel::Cart', 'MyCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCartModel'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mycart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mycart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mycart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a non-default two part model class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyOtherCart.pm');
    my $list   = catfile($app, 'root', 'myothercart', 'list');
    my $view   = catfile($app, 'root', 'myothercart', 'default');

    $helper->mk_component($app, 'controller', 'MyOtherCart', 'Handel::Cart', 'My::Cart::Model');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::Cart::Model'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myothercart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myothercart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myothercart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/myothercart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a non-default fully qualified model class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyNewCart.pm');
    my $list   = catfile($app, 'root', 'mynewcart', 'list');
    my $view   = catfile($app, 'root', 'mynewcart', 'default');

    $helper->mk_component($app, 'controller', 'MyNewCart', 'Handel::Cart', 'TestApp::M::MyNewCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyNewCartModel'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mynewcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mynewcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mynewcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mynewcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a non-default fully qualified model class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyThirdCart.pm');
    my $list   = catfile($app, 'root', 'mythirdcart', 'list');
    my $view   = catfile($app, 'root', 'mythirdcart', 'default');

    $helper->mk_component($app, 'controller', 'MyThirdCart', 'Handel::Cart', 'TestApp::Model::MyNewCartModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyNewCartModel'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mythirdcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mythirdcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mythirdcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mythirdcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a non-default checkout class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyCustomCart.pm');
    my $list   = catfile($app, 'root', 'mycustomcart', 'list');
    my $view   = catfile($app, 'root', 'mycustomcart', 'default');

    $helper->mk_component($app, 'controller', 'MyCustomCart', 'Handel::Cart', 'MyCart', 'MyCheckout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycustomcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mycustomcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mycustomcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mycustomcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mycustomcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mycheckout\/'\) %\]/);
};


## create a controller with a two part checkout class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyBestCart.pm');
    my $list   = catfile($app, 'root', 'mybestcart', 'list');
    my $view   = catfile($app, 'root', 'mybestcart', 'default');

    $helper->mk_component($app, 'controller', 'MyBestCart', 'Handel::Cart', 'MyCart', 'My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mybestcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mybestcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'mybestcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/mybestcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/mybestcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/checkout\/'\) %\]/);
};


## create a controller with a fully qualified checkout class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyWorstCart.pm');
    my $list   = catfile($app, 'root', 'myworstcart', 'list');
    my $view   = catfile($app, 'root', 'myworstcart', 'default');

    $helper->mk_component($app, 'controller', 'MyWorstCart', 'Handel::Cart', 'MyCart', 'TestApp::C::My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myworstcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myworstcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myworstcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myworstcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/myworstcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/checkout\/'\) %\]/);
};


## create a controller with a fully qualified checkout class name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyFQCart.pm');
    my $list   = catfile($app, 'root', 'myfqcart', 'list');
    my $view   = catfile($app, 'root', 'myfqcart', 'default');

    $helper->mk_component($app, 'controller', 'MyFQCart', 'Handel::Cart', 'MyCart', 'TestApp::Controller::My::Checkout');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyCart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myfqcart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myfqcart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'myfqcart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/myfqcart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/myfqcart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/checkout\/'\) %\]/);
};


## create a controller with a faulty model
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'My', 'Cart.pm');
    my $list   = catfile($app, 'root', 'my', 'cart', 'list');
    my $view   = catfile($app, 'root', 'my', 'cart', 'default');

    unlink $module;
    unlink $list;
    unlink $view;

    $helper->mk_component($app, 'controller', 'My::Cart', 'Handel::Cart', 'TestApp::Model::');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Cart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/cart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};


## create a controller with a faulty checkout
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'My', 'Cart.pm');
    my $list   = catfile($app, 'root', 'my', 'cart', 'list');
    my $view   = catfile($app, 'root', 'my', 'cart', 'default');

    unlink $module;
    unlink $list;
    unlink $view;

    $helper->mk_component($app, 'controller', 'My::Cart', 'Handel::Cart', 'Cart', 'TestApp::Controller::');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Cart'\)->storage->new_uuid/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/default';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/'\)\);/);
    file_contents_like($module, qr/\$c->stash->{'template'} = 'my\/cart\/list';/);
    file_contents_like($module, qr/\$c->res->redirect\(\$c->uri_for\('\/my\/cart\/list\/'\)\);/);
    file_contents_like($view, qr/\[% c.uri_for\('\/my\/cart\/save\/'\) %\]/);
    file_contents_like($view, qr/\[% c.uri_for\('\/checkout\/'\) %\]/);
};
