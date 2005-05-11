# $Id$
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel::Constants qw(:checkout);
    use Handel::Constraints qw(constraint_checkout_phase);
    use Handel::L10N qw(translate);
    use Module::Pluggable 2.8 instantiate => 'new' ;
};

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    my @plugins = $self->plugins($self);
    $self->{'plugins'} = \@plugins;

    $self->{'phases'} = {};

    return $self;
};

sub add_handler {
    my ($self, $phase, $ref) = @_;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a a valid CHECKOUT_PHASE_* value') . '.')
            unless constraint_checkout_phase($phase);

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a CODE reference') . '.')
            unless ref($ref) eq 'CODE';

    if (! exists $self->{'phases'}->{$phase}) {
        $self->{'phases'}->{$phase} = [];
    };

    push @{$self->{'phases'}->{$phase}}, $ref;
};

1;
__END__