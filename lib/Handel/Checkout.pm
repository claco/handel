# $Id$
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw(:checkout);
    use Handel::Constraints qw(constraint_checkout_phase constraint_uuid);
    use Handel::Exception qw(:try);
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

sub cart {

};

sub order {
    my ($self, $order) = @_;

    if ($order) {
        if (ref $order eq 'HASH') {
            $self->{'order'} = Handel::Order->load($order, 1)->next;
        } elsif (UNIVERSAL::isa($order, 'Handel::Order')) {
            $self->{'order'} = $order;
        } elsif (constaint_uuid($order)) {
            $self->{'order'} = Handel::Order->load(id => $order);
        };
    } else {
        return $self->{'order'};
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

    $self->_setup($self);

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
                $self->_teardown($self);

                return CHECKOUT_STATUS_ERROR;
            };
        };
    };

    $self->_teardown($self);

    return CHECKOUT_STATUS_OK;
};

sub _setup {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->setup($self);
        } otherwise {
            my $E = shift;
            warn $E->text;
        };
    };
};

sub _teardown {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->teardown($self);
        } otherwise {
            my $E = shift;
            warn $E->text;
        };
    };
};

1;
__END__