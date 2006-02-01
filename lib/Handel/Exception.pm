# $Id$
package Handel::Exception;
use strict;
use warnings;

BEGIN {
    use base 'Error';
    use Handel::L10N qw(translate);
    eval 'require Apache::AxKit::Exception';
    if (!$@) {
        push @__PACKAGE__::ISA, 'Apache::AxKit::Exception';
    };
};

my $lh = Handel::L10N->get_handle();

sub new {
    my $class = shift;
    my %args  = @_;
    my $text  = translate(
        $args{-text} || 'An unspecified error has occurred'
    );

    if ( defined( $args{-details} ) ) {
        $text .= ': ' . $args{-details};
    } else {
        # $text .= '.';
    };

    ## don't pass the original text
    delete $args{-text};

    return $class->SUPER::new( -text => $text, %args );
};


package Handel::Exception::Constraint;
use strict;
use warnings;

BEGIN {
    use base 'Handel::Exception';
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'The supplied field(s) failed database constraints', @_ );
};


package Handel::Exception::Argument;
use strict;
use warnings;

BEGIN {
    use base 'Handel::Exception';
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'The argument supplied is invalid or of the wrong type', @_ );
};

package Handel::Exception::Taglib;
use strict;
use warnings;

BEGIN {
    use base 'Handel::Exception';
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'The tag is out of scope or missing required child tags', @_ );
};

package Handel::Exception::Order;
use strict;
use warnings;

BEGIN {
    use base 'Handel::Exception';
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'An error occurred while while creating or validating the current order', @_ );
};

package Handel::Exception::Checkout;
use strict;
use warnings;

BEGIN {
    use base 'Handel::Exception';
};

sub new {
    my $class = shift;
    return $class->SUPER::new(
        -text => 'An error occurred during the checkout process', @_ );
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

C<Handel::Exception> subclasses L<Error> and attempts to throw exceptions when
unexpected things happen.

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
both raw DBI database constraint errors as well as  field updates that don't
pass constraints in C<Handel::Constraints>.

=head2 Handel::Exception::Argument

This exception is thrown when an invalid or unexpected argument value is passed
into methods.

=head2 Handel::Exception::Taglib

This exception is thrown when an unexpected error occurs within
C<AxKit::XSP::Handel::Cart> taglib.

=head1 METHODS

=head2 new

This returns a new C<Handel::Exception> object. This is mostly used internally
by L<Error>. In most circumstance, you don't need to call C<new> at all.
Instead, simply use the C<throw> syntax:

    use Handel::Exceptions;

    throw Handel::Exception::Taglib(
        -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
    ) if ($context[$#context] ne 'root');

=head1 SEE ALSO

L<Error>, L<Handel::Constraints>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
