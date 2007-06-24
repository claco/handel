# $Id$
package Handel::Exception;
use strict;
use warnings;

BEGIN {
    use base qw/Error/;
    use Handel::L10N qw/translate/;
    use Class::Inspector;

    if (Class::Inspector->loaded('Apache::AxKit::Exception')) {
        no strict 'vars';
        push @ISA, 'Apache::AxKit::Exception'; ## no critic
    };
};

my $lh = Handel::L10N->get_handle();

sub new {
    my $class = shift;
    my %args  = @_;
    my $text  = translate(
        $args{-text} || 'UNHANDLED_EXCEPTION'
    );

    if ( defined($args{'-details'}) && ! ref $args{'-details'}) {
        $text .= ': ' . $args{-details};
    };

    ## don't pass the original text
    delete $args{-text};

    return $class->SUPER::new( -text => $text, %args );
};

sub details {
    return shift->{'-details'};
};

sub results {
    return shift->{'-results'};
};

package Handel::Exception::Constraint;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'CONSTRAINT_EXCEPTION', @_ );
};

package Handel::Exception::Argument;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'ARGUMENT_EXCEPTION', @_ );
};

package Handel::Exception::Taglib;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'XSP_TAG_EXCEPTION', @_ );
};

package Handel::Exception::Order;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'ORDER_EXCEPTION', @_ );
};

package Handel::Exception::Checkout;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'CHECKOUT_EXCEPTION', @_ );
};

package Handel::Exception::Storage;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'STORAGE_EXCEPTION', @_ );
};

package Handel::Exception::Validation;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'VALIDATION_EXCEPTION', @_ );
};

package Handel::Exception::Virtual;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Exception/;
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'VIRTUAL_METHOD', @_ );
};

1;
__END__

=head1 NAME

Handel::Exception - Exceptions used within Handel

=head1 SYNOPSIS

    use Handel::Cart;
    use Handel::Exception' qw(:try);
    
    try {
        my $cart = Handel::Cart->new('junk crap');
    } catch Handel::Exception::Argument with {
        print 'Passed the wrong arguments to method';
    } catch Handel::Exception with {
        print 'Unknown issue with Handel';
    } catch Error with {
        print 'Unhandled exception';
    } otherwise {
        print 'aliens ate my exception';
    };

=head1 DESCRIPTION

Handel::Exception subclasses L<Error|Error> and attempts to throw exceptions
when unexpected things happen.

=head1 EXCEPTIONS

=head2 Handel::Exception

This is the base exception thrown in C<Handel>. All other exceptions subclass
C<Handel::Exception> so it's possible to catch all Handel generated exceptions
with a single C<catch> statement.

    try {
        ...
    } catch Handel::Exception with {
        my $E = shift;
        print 'Something bad happened in Handel: ' . E->text;

    } catch MyApplicationException with {
        print 'Something bad happened in MyApplication';

    };

See L<Error> for more information on how to use
exceptions.

=head2 Handel::Exception::Constraint

This exception is thrown if a database constraint is violated. This is true for
both raw DBI database constraint errors as well as field updates that don't
pass constraints in
L<Handel::Components::Constraints|Handel::Components::Constraints>.

=head2 Handel::Exception::Validation

This exception is thrown if the validation performed by
L<Handel::Components::Validation|Handel::Components::Validation> has failed.
If the validation component returned a result object, that can be found in
$E-E<gt>results.

=head2 Handel::Exception::Storage

This exception is thrown if there are any configuration or setup errors in
Handel::Storage.

=head2 Handel::Exception::Argument

This exception is thrown when an invalid or unexpected argument value is passed
into methods.

=head2 Handel::Exception::Taglib

This exception is thrown when an unexpected error occurs within
the AxKit taglibs.

=head1 METHODS

=head2 new

This returns a new Handel::Exception object. This is mostly used internally
by L<Error|Error>. In most circumstances, you don't need to call C<new> at all.
Instead, simply use the C<throw> syntax:

    use Handel::Exceptions;
    
    throw Handel::Exception::Taglib(
        -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
    ) if ($context[$#context] ne 'root');

=head2 details

Returns the details portion of the exception message if there are any.

=head2 results

Returns the data validation result errors from exceptions thrown by
L<Handel::Components::Validation|Handel::Components::Validation>.

=head1 SEE ALSO

L<Error>, L<Handel::Constraints>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
