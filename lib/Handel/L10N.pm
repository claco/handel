# $Id: L10N.pm 4 2004-12-28 03:01:15Z claco $
package Handel::L10N;
use strict;
use warnings;
use vars qw(@EXPORT_OK %Lexicon $handle);

BEGIN {
    use base 'Locale::Maketext';
    use base 'Exporter';
};

@EXPORT_OK = qw(translate);

%Lexicon = (
    _AUTO => 1
);

$handle = __PACKAGE__->get_handle();

sub translate {
    return $handle->maketext(@_);
};

1;
__END__

=head1 NAME

Handel::L10N - Localication Support

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/

=head1 METHODS

=over 4

=item C<translate>

=back
