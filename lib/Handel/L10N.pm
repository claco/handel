package Handel::L10N;
use strict;
use warnings;
use utf8;
use vars qw(@EXPORT_OK %Lexicon $handle);

BEGIN {
    use base 'Locale::Maketext';
    use base 'Exporter';
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

=head1 VERSION

    $Id$

=head1 SYNOPSIS

    use Handel::L10N qw(translate);

    warn translate('This is my message');

=head1 DESCRIPTION

This module is simply a subclass of L<Localte::Maketext>. By default it doesn't
export anything. You can either use it directly:

    use Handel::L10N;

    warn Handel::L10N::translate('My message');

You can also export C<translate> into the users namespace:

    use Handel::L10N qw(translate);

    warn translate('My message');

Thus far, the French translation comes from Googles translation tools.IF you
have the time and can do better, the help would be much appreciated.

=head1 METHODS

=head2 C<translate>

Translates the supplied text into the appropriate language if available. If no
match is available, the original text is returned.

=head1 SEE ALSO

L<Locale::Maketext>, L<Handel::L10N::us_en>, L<Handel::L10N::fr>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/




