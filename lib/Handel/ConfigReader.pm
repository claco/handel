# $Id$
package Handel::ConfigReader;
use strict;
use warnings;
use vars qw(%Defaults $MOD_PERL);

%Defaults = (
    HandelMaxQuantityAction => 'Adjust',
    HandelCurrencyCode      => 'USD',
    HandelCurrencyFormat    => 'FMT_STANDARD'
);

BEGIN {
    use Tie::Hash;
    use base 'Tie::StdHash';

    if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::RequestIO;
        require Apache2::ServerUtil;

        $MOD_PERL = 2;
    } elsif ($ENV{MOD_PERL}) {
        require Apache;

        $MOD_PERL = 1;
    } else {
        $MOD_PERL = 0;
    };
};

sub new {
    my $class = shift;
    my %config;
    tie %config, __PACKAGE__;

    return bless \%config, $class;
};

sub get {
    my ($self, $key) = (shift, shift);
    my $default = shift || $Defaults{$key} || '';

    return $self->{$key} || $default;
};

sub FETCH {
    my ($self, $key) = @_;
    my $default = $Defaults{$key} || '';
    my $value   = '';

    if ($MOD_PERL == 2) {
        my $c = eval {
            Apache2::RequestUtil->request || Apache2::ServerUtil->server;
        };

        if ($c) {
            $value = eval{$c->dir_config($key)} || $ENV{$key} || $default;
        };
    } elsif ($MOD_PERL == 1) {
        my $c = eval {
            Apache->request || Apache->server;
        };

        if ($c) {
            $value = $c->dir_config($key) || $ENV{$key} || $default;
        };
    };

    if (!$value) {
        $value = $ENV{$key} || $default;
    };

    # quick untaint for now. Assuming we'll mever get a ref from system os ENV
    if (! ref $value && $value =~ /^(.*)$/g) {
        $value = $1;
    };

    return $value;
};

sub EXISTS {
    my ($self, $key) = @_;

    return 1 if ($self->FETCH($key));
};

sub STORE {};
sub DELETE {};
sub CLEAR {};

1;
__END__

=head1 NAME

Handel::ConfigReader - Read in Handel configuration settings

=head1 SYNOPSIS

    use Handel::ConfigReader;

    my $cfg = Handel::ConfigReader-new();
    my $setting = $cfg->get('HandelMaxQuantity');

=head1 DESCRIPTION

Handel::ConfigReader is a generic wrapper to get various configuration
values. As some point this will probably get worked into XS/custom httpd.conf
directives.

Starting in version 0.11, each instance is also a tied hash. The two usages are
the same:

    my $cfg = Handel::ConfigReader->new();

    my $setting = $cfg->get('Setting');
    my $setting = $cfg->{'Setting'};

Thie latter is the preferred usage in anticipation of als integrating
Apache::ModuleConfig and custom directives which use the same hash syntax.

=head1 CONSTRUCTOR

=head2 new

Returns a new Handel::ConfigReader object.

    my $cfg = Handel::ConfigReader->new();

=head1 METHODS

=head2 get($key [, $default])

Returns the configured value for the key specified. You can use this as an
instance method or as a simpleton:

    my $setting = Handel::ConfigReader->get('HandelMaxQuantity');

    my $cfg = Handel::ConfigReader->new();
    my $setting = $cfg->get('HandelMaxQuantity');

You can also pass a default value as the second parameter. If no value is loaded
for the key specified, the default value will be returned instead.

=head1 CONFIGURATION

Various Handel runtime options can be set via C<%ENV> variables, or using
C<PerlSetVar> when running under C<mod_perl>.

=head2 HandelMaxQuantity

    PerlSetVar  HandelMaxQuantity   32
    ...
    $ENV{HandelMaxQuantity} = 32;

If defined, this sets the maximum quantity allowed for each C<Handel::Cart::Item>
in the shopping cart. By default, when the user request more than
C<HandelMaxQuantity>, C<quantity> is reset to C<HandelMaxQuantity>. If you
would rather raise an C<Handel::Exception::Constraint> instead, see
C<HandelMaxQuantityAction> below.

=head2 HandelMaxQuantityAction (Adjust|Exception)

This option defines what action should be taken when a cart items quantity is being set
to something above C<HandelMaxQuantity>. When set to C<Adjust> the quantity qill simple
be reset to C<HandelMaxQuantity> and no exception will be raised. This is the default
action.

When set to <Exception> and the quantity requested is greater than C<HandelMaxQuantity>,
a C<Handel::Exception::Constraint> exception is thrown.

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<format>.
See L<Locale::Currency::Format> for all available currency codes. The default code
is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format> for all available currency codes. The default format
used is C<FMT_STANDARD>. Just like in C<Locale::Currency::Format>, you can combine
options using C<|>.

=head2 HandelDBIDriver

The name of the DBD driver. Defaults to C<mysql>.

=head2 HandelDBIHost

The name of the database server. Defaults to C<localhost>.

=head2 HandelDBIPort

The port of the database server. Defaults to C<3306>.

=head2 HandelDBIName

The name of the database. Defaults to C<commerce>.

=head2 HandelDBIUser

The user name used to connect to the server. Defaults to C<commerce>.

=head2 HandelDBIPassword

The password used to connect to the server. Defaults to C<commerce>.

=head2 HandelDBIDSN

The full data source to the connect to the database. If a dsn is supplied
the driver/host/port and name are ignored. IF no dsn is supplied, one will
will be constructed from driver/host/port and name.

=head2 HandelPluginPaths

This resets the checkout plugin search path to a namespace of your choosing,
The default plugin search path is Handel::Checkout::Plugin::*

    PerlSetVar HandelPluginPaths MyApp::Plugins

In the example above, the checkout plugin search path will load all plugins
in the MyApp::Plugins::* namespace (but not MyApp::Plugin itself). Any plugins
in Handel::Checkout::Plugin::* will be ignored.

You can also pass a comma or space seperate list of namespaces.

    PerlSetVar HandelPluginPaths 'MyApp::Plugins, OtherApp::Plugins'

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head2 HandelAddPluginPaths

This adds an additional plugin search paths. This can be a comma or space
seperated list of namespaces.

    PerlSetVar HandelAddPluginPaths  'MyApp::Plugins, OtherApp::Plugins'

In the example above, when a checkout process is loaded, it will load
all plugins in the Handel::Checkout::Plugin::*, MyApp::Plugins::*, and
OtherApp::Plugins namespaces.

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head2 HandelIgnorePlugins

This is a comma/space seperated list [or an anonymous array, or a regex outside of httpd.conf] of plugins to ignore when loading
all available plugins in the given namespaces.

    PerlSetVar HandelIgnorePlugins 'Handel::Checkout::Plugin::Initialize'

    $ENV{'HandelIgnorePlugins'} = 'Handel::Checkout::Plugin::Initialize';
    $ENV{'HandelIgnorePlugins'} = ['Handel::Checkout::Plugin::Initialize'];
    $ENV{'HandelIgnorePlugins'} = qr/^Handel::Checkout::Plugin::(Initialize|Validate)$/;

If the Handel::Checkout::Plugin namespace has the following modules:

    Handel::Checkout::Plugin::Initialize
    Handel::Checkout::Plugin::ValidateAddress
    Handel::Checkout::Plugin::FaxDelivery
    Handel::Checkout::Plugin::EmailDelivery

all of the modules above will be loaded <b>except</b> Handel::Checkout::Plugin::Initialize.
All plugins in any other configured namespaces will be loaded.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the plugins in
HandelLoadPlugins will be loaded, unless they are also in HandelIgnorePlugins in which case
they will be ignored.

=head2 HandelLoadPlugins

This is a comma or space seperated list [or an anonymous array, or a regex outside of httpd.conf] of plugins to be loaded from the available namespaces.

    PerlSetVar HandelLoadPlugins 'Handel::Checkout::Plugin::ValidateAddress'

    $ENV{'HandelLoadPlugins'} = 'Handel::Checkout::Plugin::ValidateAddress';
    $ENV{'HandelLoadPlugins'} = ['Handel::Checkout::Plugin::ValidateAddress'];
    $ENV{'HandelLoadPlugins'} = qr/^Handel::Checkout::Plugin::(ValidateAddress|Authorize)$/;

If the following plugins are available in all configured namespaces:

    Handel::Checkout::Plugin::Initialize
    Handel::Checkout::Plugin::ValidateAddress
    Handel::Checkout::Plugin::FaxDelivery
    Handel::Checkout::Plugin::EmailDelivery
    MyApp::Plugin::VerifiedByVisa
    MyApp::Plugin::WarehouseUpdate

only Handel::Checkout::Plugin::ValidateAddress will be loaded. All other plugins in all
configured namespaces will be ignored.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the plugins in
HandelLoadPlugins will be loaded, unless they are also in HandelIgnorePlugins in which case
they will be ignored.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
