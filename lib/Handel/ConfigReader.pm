package Handel::ConfigReader;
use strict;
use warnings;
use vars qw(%Defaults);
use Tie::Hash;
use base 'Tie::StdHash';

%Defaults = (
    HandelMaxQuantityAction => 'Adjust'
);

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

    if ($ENV{MOD_PERL}) {
        require Apache;
        my $r = Apache->request;

        $value = $r->dir_config($key) || $default;
    };

    if (!$value) {
        $value = $ENV{$key} || $default;
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

=head1 VERSION

    $Id$

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

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
