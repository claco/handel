#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use Module::Starter::Handel;
    use Getopt::Long;
    use Pod::Usage;
};

my $help    = 0;
my $author  = 'Author';
my $email   = 'author@example.com';
my $builder = 'ExtUtils::MakeMaker';
my $force   = 0;
my $verbose = 1;
my $version = 0;
my $distro;
my $directory;

GetOptions(
    'help|?'          => \$help,
    'author=s'        => \$author,
    'email=s'         => \$email,
    'distro=s'        => \$distro,
    'directory|dir=s' => \$directory,
    'builder=s'       => \$builder,
    'force'           => \$force,
    'verbose!'        => \$verbose,
    'version'         => \$version
) || pod2usage(1);

if ($version) {
    require Handel;
    print "Handel ", Handel->VERSION, "\n";
    exit;
};

pod2usage(1) if ($help || !$ARGV[0]);

my $module = $ARGV[0];
if (!$distro) {
    $distro = $module;
    $distro =~ s/::/-/g;
};

Module::Starter::Handel->create_distro(
    author  => $author,
    email   => $email,
    builder => $builder,
    force   => $force,
    verbose => $verbose,
    modules => [$module],
    distro  => $distro,
    dir     => $directory,
);

print "Created starter directories and files\n";

1;
__END__

=head1 NAME

handel - Bootstrap a Handel application

=head1 SYNOPSIS

handel [options] application-name

Options:

    --help       Show this message
    --author     Your name
    --email      Your email address
    --distro     Name of dist. Defaults to application name
    --dir        Name of directory to to create dist in
    --builder    ExtUtils::MakeMaker (default) or Module::Build
    --force      Overwrite existing files
    --noverbose  Turn off progress messages
    --version    The installed version

Example:

    handel MyProject
    handel --distro My-Project-Dist --dir MyProject My::Project

=head1 DESCRIPTION

The C<handel.pl> script creates a skeleton framework for a new Handel based
application using the recommend style of subclassing for easy customization.

    Created MyProject
    Created MyProject\lib\MyProject
    Created MyProject\lib\MyProject\Cart.pm
    Created MyProject\lib\MyProject\Cart
    Created MyProject\lib\MyProject\Cart\Item.pm
    Created MyProject\lib\MyProject\Storage
    Created MyProject\lib\MyProject\Storage\Cart.pm
    Created MyProject\lib\MyProject\Storage\Cart
    Created MyProject\lib\MyProject\Storage\Cart\Item.pm
    Created MyProject\lib\MyProject\Order.pm
    Created MyProject\lib\MyProject\Order
    Created MyProject\lib\MyProject\Order\Item.pm
    Created MyProject\lib\MyProject\Storage\Order.pm
    Created MyProject\lib\MyProject\Storage\Order
    Created MyProject\lib\MyProject\Storage\Order\Item.pm
    Created MyProject\lib\MyProject\Checkout.pm
    Created MyProject\t
    Created MyProject\t\pod_syntax.t
    Created MyProject\t\pod_spelling.t
    Created MyProject\t\basic.t
    Created MyProject\t\pod_coverage.t
    Created MyProject\.cvsignore
    Created MyProject\Makefile.PL
    Created MyProject\MANIFEST
    Created MyProject\script\myapp_handel.pl

See L<Handel::Manual::QuickStart> for more information on creating your first
Handel based application.

=head1 SEE ALSO

L<Handel::Manual>, L<Handel::Manual::QuickStart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
