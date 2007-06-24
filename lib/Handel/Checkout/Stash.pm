# $Id$
package Handel::Checkout::Stash;
use strict;
use warnings;

BEGIN {
    use Handel::L10N qw/translate/;
};

sub new {
    my ($class, $data) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) if defined $data && ref($data) ne 'HASH'; ## no critic

    my $self = bless $data || {}, $class;

    return $self;
};

sub clear {
    my $self = shift;

    %{$self} = ();

    return;
};

1;
__END__

=head1 NAME

Handel::Checkout::Stash - Basic storage for checkout plugins during processing

=head1 SYNOPSIS

    use Handel::Checkout;
    
    my $checkout = Handel::Checkout->new;
    $checkout->process;
    
    # later in some plugin
    sub myhandler {
        my ($self, $ctx) = @_;

        $ctx->stash->{'mystuff'};
        ...
    };
    
    # later in some other plugin
    sub myhandler {
        my ($self, $ctx) = @_;
    
        my $stuff = $ctx->stash->{'mystuff'};
        ...
    };

=head1 DESCRIPTION

Handel::Checkout::Stash is used by Handel::Checkout::Plugin plugins to pass data
between themselves during a call to C<process>. Before and after each call to
process, C<clear> is called is empty the stash.

To prevent this behavior, simply subclass this package with an empty clear and
tell Handel::Checkout to use the new stash instead:

    package MyApp::Stash;
    use strict;
    use warnings;
    use base 'Handel::Checkout::Stash';
    
    sub clear {};
    
    ---
    
    use Handel::Checkout;
    
    my $co = Handel::Checkout->new({
        stash => MyApp::Stash->new
    });

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%data

=back

Creates a new instance of Handel::Checkout::Stash. You can optionally pass a hash
reference to new which will be blessed into the new stash instance.

=head1 METHODS

=head2 clear

Empties the contents of the stash.

The method is called before the call to
$plugin->setup so plugins can set stash data, and the stash remains until the
next call to process so $plugin->teardown can read any remaining stash data
before C<process> ends.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
