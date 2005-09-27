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

    plan tests => 5;

    use_ok('Catalyst::Helper');
};

my $helper = Catalyst::Helper->new;
my $app = 'TestApp';


## create the test app
{
    chdir('t');
    rmtree('TestApp');

    $helper->mk_app($app);
    $FindBin::Bin = catdir(cwd, $app, 'bogusdir');
};


## create the default model
{
    my $file = catfile($app, 'lib', $app, 'M', 'Cart.pm');
    $helper->mk_component($app, 'model', 'Cart', 'Handel::Cart', 'testdsn', 'testuser', 'testpass');
    file_exists_ok($file);
    file_contents_like($file, qr/'testdsn'/);
    file_contents_like($file, qr/'testuser'/);
    file_contents_like($file, qr/'testpass'/);
};
