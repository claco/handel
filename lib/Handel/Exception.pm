# $Id: Exception.pm 4 2004-12-28 03:01:15Z claco $
package Handel::Exception;
use strict;
use warnings;

BEGIN {
    use base 'Error';
    use Handel::L10N qw(translate);
};

my $lh = Handel::L10N->get_handle('fr');

sub new {
    my $class = shift;
    my %args  = @_;
    my $text  = translate(
        $args{-text} || 'An unspecified error has ocurred'
    );

    if ( defined( $args{-details} ) ) {
        $text .= ': ' . $args{-details};
    } else {
        $text .= '.';
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

1;
__END__

=head1 NAME

Handel::Exception - Exceptions

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/

=head1 METHODS

=over 4

=item C<new>

=back
