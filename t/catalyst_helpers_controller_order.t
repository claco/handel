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

    plan tests => 60;

    use_ok('Catalyst::Helper');
    use_ok('Catalyst::Helper::Controller::Handel::Order');
    use_ok('Handel::Constants');
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


## create the default order controller
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'Orders.pm');
    my $list     = catfile($app, 'root', 'orders', 'default');
    my $view     = catfile($app, 'root', 'orders', 'view');
    my $messages = catfile($app, 'root', 'orders', 'messages.yml');
    my $profiles = catfile($app, 'root', 'orders', 'profiles.yml');

    $helper->mk_component($app, 'controller', 'Orders', 'Handel::Order');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_exists_ok($messages);
    file_exists_ok($profiles);
    file_contents_like($module,   qr/->model\('Order'\)/);
    file_contents_like($module,   qr/= 'orders\/view'/);
    file_contents_like($module,   qr/= 'orders\/default'/);
    file_contents_like($view,     qr/INCLUDE orders\/errors/);
    file_contents_like($list,     qr/\[% c.uri_for\('\/orders\/view'/);
    file_contents_like($messages, qr/^orders\/view:/);
    file_contents_like($profiles, qr/^orders\/view:/);
};


## load it up
{
    my $lib = catfile(cwd, $app, 'lib');
    eval "use lib '$lib';use $app\:\:Controller\:\:Orders";
    ok(!$@, 'loaded new class');
};


## create the default order controller with custom model name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyOrders.pm');
    my $list   = catfile($app, 'root', 'myorders', 'default');
    my $view   = catfile($app, 'root', 'myorders', 'view');

    $helper->mk_component($app, 'controller', 'MyOrders', 'Handel::Order', 'MyOrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyOrderModel'\)/);
    file_contents_like($module, qr/= 'myorders\/view'/);
    file_contents_like($module, qr/= 'myorders\/default'/);
    file_contents_like($view,   qr/INCLUDE myorders\/errors/);
    file_contents_like($list,   qr/\[% c.uri_for\('\/myorders\/view'/);
};


## create the default order controller with custom two part model name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyOtherOrders.pm');
    my $list   = catfile($app, 'root', 'myotherorders', 'default');
    my $view   = catfile($app, 'root', 'myotherorders', 'view');

    $helper->mk_component($app, 'controller', 'MyOtherOrders', 'Handel::Order', 'My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)/);
    file_contents_like($module, qr/= 'myotherorders\/view'/);
    file_contents_like($module, qr/= 'myotherorders\/default'/);
    file_contents_like($view,   qr/INCLUDE myotherorders\/errors/);
    file_contents_like($list,   qr/\[% c.uri_for\('\/myotherorders\/view'/);
};


## create the default order controller with fully qualified model name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyCustomOrder.pm');
    my $list   = catfile($app, 'root', 'mycustomorder', 'default');
    my $view   = catfile($app, 'root', 'mycustomorder', 'view');

    $helper->mk_component($app, 'controller', 'MyCustomOrder', 'Handel::Order', 'TestApp::M::My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)/);
    file_contents_like($module, qr/= 'mycustomorder\/view'/);
    file_contents_like($module, qr/= 'mycustomorder\/default'/);
    file_contents_like($view,   qr/INCLUDE mycustomorder\/errors/);
    file_contents_like($list,   qr/\[% c.uri_for\('\/mycustomorder\/view'/);
};


## create the default order controller with fully qualified model name
{
    my $module = catfile($app, 'lib', $app, 'Controller', 'MyThirdOrder.pm');
    my $list   = catfile($app, 'root', 'mythirdorder', 'default');
    my $view   = catfile($app, 'root', 'mythirdorder', 'view');

    $helper->mk_component($app, 'controller', 'MyThirdOrder', 'Handel::Order', 'TestApp::Model::My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)/);
    file_contents_like($module, qr/= 'mythirdorder\/view'/);
    file_contents_like($module, qr/= 'mythirdorder\/default'/);
    file_contents_like($view,   qr/INCLUDE mythirdorder\/errors/);
    file_contents_like($list,   qr/\[% c.uri_for\('\/mythirdorder\/view'/);
};


## create the default order controller with bogus order model
{
    my $module   = catfile($app, 'lib', $app, 'Controller', 'Orders.pm');
    my $list     = catfile($app, 'root', 'orders', 'default');
    my $view     = catfile($app, 'root', 'orders', 'view');
    my $messages = catfile($app, 'root', 'orders', 'messages.yml');
    my $profiles = catfile($app, 'root', 'orders', 'profiles.yml');

    unlink $module;
    unlink $list;
    unlink $view;
    unlink $messages;
    unlink $profiles;

    $helper->mk_component($app, 'controller', 'Orders', 'Handel::Order', 'TestApp::Model::');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_exists_ok($messages);
    file_exists_ok($profiles);
    file_contents_like($module,   qr/->model\('Order'\)/);
    file_contents_like($module,   qr/= 'orders\/view'/);
    file_contents_like($module,   qr/= 'orders\/default'/);
    file_contents_like($view,     qr/INCLUDE orders\/errors/);
    file_contents_like($list,     qr/\[% c.uri_for\('\/orders\/view'/);
    file_contents_like($messages, qr/^orders\/view:/);
    file_contents_like($profiles, qr/^orders\/view:/);
};
