# $Id$
package Handel::Exception;
use strict;
use warnings;

BEGIN {
    use base 'Error';
    use Handel::L10N qw(translate);
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

=head2 C<Handel::Exception>

This is the base exception thrown in C<Handel>. All other exceptions subclass
C<Handel::Exception> so it's possibly to catch all Handel generated exceptions
with a single C<catch> statement.

    try {
        ...
    } catch Handel::Exception with {
        my $E = shift;
        print 'Something bad happened in Handel: ' . E->text;

    } catch MyApplicaitonException with {
        print 'Something bad happened in MyApplication';

    };

See L<Error> for more information on how to use
exceptions.

=head2 C<Handel::Exception::Constraint>

This exception is thrown if a database constraint is violated. This is true for
both raw DBI database constraint errors as well as  field updates that don't
pass constraints in C<Handel::Constraints>.

=head2 C<Handel::Exception::Argument>

This exception is thrown when an invalid or unexpected argument value is passed
into methods.

=head1 SEE ALSO

L<Error>, L<Handel::constraints>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
