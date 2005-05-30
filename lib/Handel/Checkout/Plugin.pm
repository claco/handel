# $Id$
package Handel::Checkout::Plugin;
use strict;
use warnings;

sub new {
    my ($class, $ctx) = @_;
    my $self = bless {}, ref $class || $class;

    $self->init();

    return $self;
};

sub init {

};

sub register {
    warn "Attempt to register plugin that hasn't defined 'register'!";
};

1;
__END__