# $Id$
## no critic (ProhibitPackageVars)
package Handel::L10N;
use strict;
use warnings;
use utf8;
use vars qw/@EXPORT_OK %Lexicon $handle/;

BEGIN {
    use base qw/Locale::Maketext Exporter/;
};

@EXPORT_OK = qw(translate);

%Lexicon = (
    _AUTO => 1
);

sub translate {
    my $handle = __PACKAGE__->get_handle();

    return $handle->maketext(@_);
};

1;
__END__

=head1 NAME

Handel::L10N - Localization module for Handel

=head1 SYNOPSIS

    use Handel::L10N qw(translate);
    
    warn translate('This is my message');

=head1 DESCRIPTION

This module is simply a subclass of C<Locale::Maketext>. By default it doesn't
export anything. You can either use it directly:

    use Handel::L10N;

    warn Handel::L10N::translate('My message');

You can also export C<translate> into the callers namespace:

    use Handel::L10N qw/translate/;

    warn translate('My message');

If you have the time and can do a language, the help would be much appreciated.
If you're going to email a translation module, please Gzip it first. It's not
uncommon for an email server along the way to trash UTF-8 characters in the
.pm attachment text.

There is also a t/l10n_lexicon_synced.t test that ensures that each lexicon
has the same number of keys as the English version. Please make sure to
run/update that test before submitting your lexicon.

=head1 FUNCTIONS

=head2 translate

=over

=item Arguments: $message

=back

Translates the supplied text into the appropriate language if available. If no
match is available, the original text is returned.

    print translate('foo was here');

=head1 SEE ALSO

L<Locale::Maketext>, L<Handel::L10N::us_en>, L<Handel::L10N::fr>,
L<Handel::L10N::zh_tw>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
