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

    plan tests => 46;

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


## create the default order controller
{
    my $module = catfile($app, 'lib', $app, 'C', 'Orders.pm');
    my $list   = catfile($app, 'root', 'orders', 'list.tt');
    my $view   = catfile($app, 'root', 'orders', 'view.tt');

    $helper->mk_component($app, 'controller', 'Orders', 'Handel::Order');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('Orders'\)->load/);
    file_contents_like($module, qr/= 'orders\/view.tt'/);
    file_contents_like($module, qr/= 'orders\/list.tt'/);
    file_contents_like($view,   qr/\[% base _ 'orders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'orders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'orders\/view\/'/);
};


## create the default order controller with custom model name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyOrders.pm');
    my $list   = catfile($app, 'root', 'myorders', 'list.tt');
    my $view   = catfile($app, 'root', 'myorders', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyOrders', 'Handel::Order', 'MyOrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('MyOrderModel'\)->load/);
    file_contents_like($module, qr/= 'myorders\/view.tt'/);
    file_contents_like($module, qr/= 'myorders\/list.tt'/);
    file_contents_like($view,   qr/\[% base _ 'myorders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'myorders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'myorders\/view\/'/);
};


## create the default order controller with custom two part model name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyOtherOrders.pm');
    my $list   = catfile($app, 'root', 'myotherorders', 'list.tt');
    my $view   = catfile($app, 'root', 'myotherorders', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyOtherOrders', 'Handel::Order', 'My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)->load/);
    file_contents_like($module, qr/= 'myotherorders\/view.tt'/);
    file_contents_like($module, qr/= 'myotherorders\/list.tt'/);
    file_contents_like($view,   qr/\[% base _ 'myotherorders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'myotherorders\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'myotherorders\/view\/'/);
};


## create the default order controller with fully qualified model name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyCustomOrder.pm');
    my $list   = catfile($app, 'root', 'mycustomorder', 'list.tt');
    my $view   = catfile($app, 'root', 'mycustomorder', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyCustomOrder', 'Handel::Order', 'TestApp::M::My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)->load/);
    file_contents_like($module, qr/= 'mycustomorder\/view.tt'/);
    file_contents_like($module, qr/= 'mycustomorder\/list.tt'/);
    file_contents_like($view,   qr/\[% base _ 'mycustomorder\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'mycustomorder\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'mycustomorder\/view\/'/);
};


## create the default order controller with fully qualified model name
{
    my $module = catfile($app, 'lib', $app, 'C', 'MyThirdOrder.pm');
    my $list   = catfile($app, 'root', 'mythirdorder', 'list.tt');
    my $view   = catfile($app, 'root', 'mythirdorder', 'view.tt');

    $helper->mk_component($app, 'controller', 'MyThirdOrder', 'Handel::Order', 'TestApp::Model::My::OrderModel');
    file_exists_ok($module);
    file_exists_ok($list);
    file_exists_ok($view);
    file_contents_like($module, qr/->model\('My::OrderModel'\)->load/);
    file_contents_like($module, qr/= 'mythirdorder\/view.tt'/);
    file_contents_like($module, qr/= 'mythirdorder\/list.tt'/);
    file_contents_like($view,   qr/\[% base _ 'mythirdorder\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'mythirdorder\/' %\]/);
    file_contents_like($list,   qr/\[% base _ 'mythirdorder\/view\/'/);
};
