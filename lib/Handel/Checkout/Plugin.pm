# $Id$
package Handel::Checkout::Plugin;
use strict;
use warnings;

sub new {
    my ($class, $ctx) = @_;
    my $self = bless {}, ref $class || $class;

    $self->init($ctx);

    return $self;
};

sub init {

};

sub setup {

};

sub teardown {

};

sub register {
    warn "Attempt to register plugin that hasn't defined 'register'!";
};

1;
__END__

=head1 NAME

Handel::Checkout::Plugin - Base module for Handle::Checkout plugins

=head1 SYNOPSIS

    package MyPackage::FaxOrder;
    use Handel::Constants qw(:checkout);
    use base 'Handel::Checkout::Plugin';

    sub register {
        my ($self, $ctx) = @_;

        $ctx->add_handler(CHECKOUT_PHASE_DELIVER, \&deliver);
    };

    sub deliver {
        my ($self, $ctx) = @_;

        ...

        return CHECKOUT_HANDLER_OK;
    };

=head1 DESCRIPTION

C<Handel::Checkout::Plugin> is the base module for all checkout pipeline
plugins used in C<Handel::Checkout>.

=head1 CONSTRUCTOR

=head2 new

Returns as new Handle::Checkout::Plugin object. This method is inherited
by all subclasses and called when each plugin is loaded into the checkout
pipeline. There should be no need to call this method directly.

=head1 METHODS

The following methods are called during various times in the checkout process.
Each method receives a reference to its instance as well as reference to
the current checkout process:

    sub init {
        my ($self, $ctx) = @_;
    };

=head2 init

This method is called then the plugin is first created and loaded into
the checkout pipeline. While a pipeline can be processed more than once, init
will only be called the first time the plugin is loaded.

=head2 register

After a plugin is loaded, C<register> is called so the plugin can register
itself with the various phases in the current checkout pipeline process
using C<add_handler> in C<Handel::Checkout>:

    sub register {
        my ($self, $ctx) = @_;

        $ctx->add_handler(CHECKOUT_PHASE_DELIVER, \&deliver);
    };

A plugin can register any number of methods with any number of phases.

=head2 setup

Each time a checkout pipeline is processed, the C<setup> method is called
on all registered plugins to allow each plugin to perform any
necessary preperation before its registered handler subs are called.

=head2 teardown

Each time a checkout pipeline is finished being processed, the
C<teardown> method is called on all registered plugins to allow each plugin
to performa any cleanup it may need to do.

=head1 SEE ALSO

L<Handel::Checkout>, L<Handel::Constants>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
