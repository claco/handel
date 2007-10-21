# $Id$
package Handel::Components::Validation;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Validation/;
    use Scalar::Util qw/blessed/;
};

sub throw_exception { ## no critic (RequireFinalReturn)
    my ($self, $exception) = @_;

    if (blessed $exception) {
        $self->next::method(
            Handel::Exception::Validation->new(-results => $exception)
        );
    } else {
        $self->next::method(
            Handel::Exception::Validation->new(-details => $exception)
        );
    };
};

sub validate {
    my $self = shift;
    my $result;

    eval {
        $result = $self->next::method(@_);
    };
    if ($@) {
        $self->throw_exception($@);
    };

    return $result;
};

1;
__END__

=head1 NAME

Handel::Components::Validation - Column validation for schemas

=head1 SYNOPSIS

    package MySchema::Table;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components('+Handel::Component::Validation');
    __PACKAGE__->validation(
        module  => 'FormValidator::Simple',
        profile => [ ... ],
        auto    => 1
    );
    
    1;

=head1 DESCRIPTION

Handel::Components::Validation is a customized version of
L<DBIx::Class::Validation> for use in cart/order schemas.

There is no real reason to load this component into your schema table classes
directly. If you set a profile using Handel::Storage->validation_profile, this
component will be loaded into the appropriate schema source class automatically.

If validation
fails, a L<Handel::Exception::Validation|Handel::Exception::Validation> will be
thrown containing the the result object returned from the validation module.

=head2 validate

Validates the data using the specified validation module/profile. If validation
succeeds, the result object from the validation module is returned. If
validation fails, a Handel:Exception::Validation will be thrown.

=head2 throw_exception

Wraps DBIx::Class::Validation exceptions in Handel exceptions and rethrows. See
L<DBIx::Class::Row/throw_exception> for more information about throw_exception.

=head1 SEE ALSO

L<DBIx::Class::Validation>, L<FormValidator::Simple>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
