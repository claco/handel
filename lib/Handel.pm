package Handel;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.01_08';

1;
__END__

=head1 NAME

Handel - Simple commerce framework with AxKit support

=head1 VERSION

    $Id$

=head1 DESCRIPTION

Handel is a quick and not-so-dirty ecommerce framework with L<AxKit> taglib
support. It was started for the conversion of an IIS/ASP based commerce site to
Apache/ModPerl, but I decided that is might be useful to others so here it is
on CPAN.

For the curious, Handel is German for commerce.

=head1 REQUIREMENTS

=head2 Prerequisites

The following modules are required for Handel to work properly. Older versions
may work fine. For now, these are the versions I have installed and verified to
work correctly.

=over

=item C<Class::DBI> version 0.96+

=item C<DBI> version 1.36+

=item C<Error> version 0.14+

=item C<Locale::Maketext> version 1.06+

=item C<UUID*/GUID*>

At least one of the following modules are required to create uuids:
L<UUID> 0.02, L<Win32::Guidgen> 0.04, L<Win32API::GUID> 0.02,
or L<Data::UUID> 0.10.

=item C<Axit> 1.6.2+

C<AxKit> is only required if you plan on using C<Handel> within XSP using the
supplied taglibs.

=back

=head2 Optional Modules

The following modules are only required for the test suite:

=over

=item C<Test::More> version 0.48+

The C<Test::More> included with perl 5.8.4 and C<Test::More> <= 0.48 have issues
with ithreads that usually cause crashes in C<Class::DBI> tests.

=item C<Pod::Coverage> version 0.14+

The pod coverage tests may fail complaining about missing pod for methods if
Pod::Coverage < 0.14 is installed. This is due to certain syntax variations of
the pod with escaped gt/lt. I may just alter the pod and bump this version down
if there is enough feedback to do so.

=item C<Test::Pod> version 1.00+

C<Test::Pod> 1.00 added the C<all_pod_files_ok()> method which makes my life
easier. :-)

=item C<Test::Pod::Coverage> version 1.04+

C<Test::Pod::Coverage> 1.04 was made taint safe, and we run the tests with -wT
like good girls and boys.

=back

=head1 SEE ALSO

L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/











