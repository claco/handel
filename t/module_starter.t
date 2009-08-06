#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Cwd;
    use File::Path;
    use File::Spec::Functions;

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    eval 'use Module::Starter';
    if (!$@) {
        plan tests => 62;
    } else {
        plan skip_all => 'Module::Starter not installed';
    };

    use_ok('Module::Starter::Handel');
};


## get nothing for no template
is(Module::Starter::Handel->new(__base_name => 'foo')->module_guts('BOGUS'), '', 'module_gets returns empty string for nonexistant template');

## setup var
chdir('t');
mkdir('var') unless -d 'var';
chdir('var');


## create test app without name
my $app = 'MyProject';
{
    rmtree($app);
    Module::Starter::Handel->create_distro(
        author  => 'Christopher H. Laco',
        email   => 'claco@chrislaco.com',
        builder => 'ExtUtils::MakeMaker',
        force   => 1
    );

    file_exists_ok(catfile($app, 'lib', "$app.pm"));

    my $lib = catdir($app, 'lib', $app);
    file_exists_ok(catfile($lib, 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Cart', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Order.pm'));
    file_exists_ok(catfile($lib, 'Order', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Checkout.pm'));

    my $t = catdir($app, 't');
    file_exists_ok(catfile($t, 'basic.t'));
    file_exists_ok(catfile($t, 'pod_coverage.t'));
    file_exists_ok(catfile($t, 'pod_syntax.t'));
    file_exists_ok(catfile($t, 'pod_spelling.t'));

    my $scripts = catdir($app, 'script');
    file_exists_ok(catfile($scripts, 'myproject_handel.pl'));
};


## create test app with name
$app = 'TestApp';
{
    rmtree($app);
    Module::Starter::Handel->create_distro(
        author  => 'Christopher H. Laco',
        email   => 'claco@chrislaco.com',
        builder => 'ExtUtils::MakeMaker',
        modules => [$app],
        force   => 1
    );

    file_exists_ok(catfile($app, 'lib', "$app.pm"));

    my $lib = catdir($app, 'lib', $app);
    file_exists_ok(catfile($lib, 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Cart', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Order.pm'));
    file_exists_ok(catfile($lib, 'Order', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Checkout.pm'));

    my $t = catdir($app, 't');
    file_exists_ok(catfile($t, 'basic.t'));
    file_exists_ok(catfile($t, 'pod_coverage.t'));
    file_exists_ok(catfile($t, 'pod_syntax.t'));
    file_exists_ok(catfile($t, 'pod_spelling.t'));

    my $scripts = catdir($app, 'script');
    file_exists_ok(catfile($scripts, 'testapp_handel.pl'));
};


## create test app with name and distro
$app = 'DistApp';
{
    rmtree($app);
    Module::Starter::Handel->create_distro(
        author  => 'Christopher H. Laco',
        email   => 'claco@chrislaco.com',
        builder => 'ExtUtils::MakeMaker',
        modules => [$app],
        force   => 1,
        distro  => 'MyDistro'
    );

    file_exists_ok(catfile('MyDistro', 'lib', "$app.pm"));

    my $lib = catdir('MyDistro', 'lib', $app);
    file_exists_ok(catfile($lib, 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Cart', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Order.pm'));
    file_exists_ok(catfile($lib, 'Order', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Checkout.pm'));

    my $t = catdir('MyDistro', 't');
    file_exists_ok(catfile($t, 'basic.t'));
    file_exists_ok(catfile($t, 'pod_coverage.t'));
    file_exists_ok(catfile($t, 'pod_syntax.t'));
    file_exists_ok(catfile($t, 'pod_spelling.t'));

    my $scripts = catdir('MyDistro', 'script');
    file_exists_ok(catfile($scripts, 'distapp_handel.pl'));
};


## create test app in a directory
$app = 'MyApp';
{
    rmtree('Foo');
    Module::Starter::Handel->create_distro(
        author  => 'Christopher H. Laco',
        email   => 'claco@chrislaco.com',
        builder => 'ExtUtils::MakeMaker',
        modules => [$app],
        force   => 1,
        dir     => 'Foo'
    );

    file_exists_ok(catfile('Foo', 'lib', "$app.pm"));

    my $lib = catdir('Foo', 'lib', $app);
    file_exists_ok(catfile($lib, 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Cart', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Cart', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Order.pm'));
    file_exists_ok(catfile($lib, 'Order', 'Item.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order.pm'));
    file_exists_ok(catfile($lib, 'Storage', 'Order', 'Item.pm'));    
    file_exists_ok(catfile($lib, 'Checkout.pm'));

    my $t = catdir('Foo', 't');
    file_exists_ok(catfile($t, 'basic.t'));
    file_exists_ok(catfile($t, 'pod_coverage.t'));
    file_exists_ok(catfile($t, 'pod_syntax.t'));
    file_exists_ok(catfile($t, 'pod_spelling.t'));

    my $scripts = catdir('Foo', 'script');
    file_exists_ok(catfile($scripts, 'myapp_handel.pl'));
};
