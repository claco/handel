# $Id$
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw(:checkout);
    use Handel::Constraints qw(constraint_checkout_phase);
    use Handel::L10N qw(translate);
    use Module::Pluggable 2.8 instantiate => 'new';
};

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;
    my @plugins = $self->plugins($self);

    $self->{'plugins'} = \@plugins;

    foreach (@plugins) {
        $_->register($self);
    };

    return $self;
};

sub add_handler {
    my ($self, $phase, $ref) = @_;
    my ($package) = caller;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a a valid CHECKOUT_PHASE_* value') . '.')
            unless constraint_checkout_phase($phase);

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a CODE reference') . '.')
            unless ref($ref) eq 'CODE';

    foreach (@{$self->{'plugins'}}) {
        if (ref $_ eq $package) {
            push @{$self->{'handlers'}->{$phase}}, [$_, $ref];
            last;
        };
    };
};

sub phases {
    my ($self, $phases) = @_;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate(
                'Param 1 is not an ARRAY reference') . '.')
                unless ref($phases) eq 'ARRAY';

        $self->{'phases'} = $phases;
    } else {
        return $self->{'phases'} || CHECKOUT_DEFAULT_PHASES;
    };
};

sub process {
    my $self = shift;
    my $phases = shift;

     if ($phases) {
         throw Handel::Exception::Argument( -details =>
             translate(
                 'Param 1 is not an ARRAY reference') . '.')
                 unless ref($phases) eq 'ARRAY';

         $self->{'phases'} = $phases;
    } else {
        $phases = $self->{'phases'} || CHECKOUT_DEFAULT_PHASES;
    };

    foreach my $phase (@{$phases}) {
        foreach my $handler (@{$self->{'handlers'}->{$phase}}) {
            my $status = $handler->[1]->($handler->[0], $self);

            if ($status == CHECKOUT_HANDLER_ERROR) {
                return CHECKOUT_STATUS_ERROR;
            };
        };
    };

    return CHECKOUT_STATUS_OK;
};

1;
__END__