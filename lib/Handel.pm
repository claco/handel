# $Id$
package Handel;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.17_03';

1;
__END__

=head1 NAME

Handel - Simple commerce framework with AxKit/TT2 support

=head1 DESCRIPTION

Handel is a quick and not-so-dirty ecommerce framework with L<AxKit> taglib
support and TT2 (template Toolkit) support. It was started for the conversion
of an IIS/ASP based commerce site to Apache/ModPerl, but I decided that is
might be useful to others so here it is on CPAN.

For the curious, Handel is German for commerce.

=head1 FEATURES

=over

=item Add/Update/Delete/Save/Restore Cart Contents

=item Full AxKit XSP Taglib Support

=item Template Toolkit 2 Plugin Support

=item Currency Conversion

=item Currency Formatting

=item Basic Localization Support

=item Multiple Database Support

=back

=head1 REQUIREMENTS

=head2 Prerequisites

The following modules are required for Handel to work properly. Older versions
may work fine, but hese are the versions I have installed and verified to
work correctly. IF you have older versious and all tests pass, send me an email
and I'll lower the version requirements.

=over

=item Class::DBI

C<Class::DBI> version 0.96 or greater.

=item DBI

C<DBI> version 1.36 or greater.

=item Error

C<Error> version 0.14 or greater.

=item Locale::Maketext

C<Locale::Maketext> version 1.06 or greater.

=item Data::UUID

At least one of the following modules are required to create uuids:
C<UUID> 0.02, C<Win32::Guidgen> 0.04, C<Win32API::GUID> 0.02,
or C<Data::UUID> 0.10.

=back

=head2 Optional Modules

The following modules are not required for Handel to run, although some
features may be unavailable without them.

=over

=item AxKit

C<AxKit> version 1.61 or greater.

C<AxKit> is only required if you plan on using C<Handel> within XSP using the
supplied taglibs.

=item Locale::Currency::Format

C<Locale::Currency::Format> version 1.22 or greater.

When present, this module allows all prices to be formatted to specific
currency codes and formats.

=item Finance::Currency::Convert::WebserviceX

C<Finance::Currency::Convert::WebserviceX> version 0.03 or greater.

When present, this module allows all prices to be converted from one currency
to another.

=item Locale::Currency

C<Locale::Currency> version 2.07 or greater.

When present, this module allows all conversion and currency codes
to be verified as real 3 letter ISO currency codes.

=item Template

C<Template> version 2.07 or greater.

C<Template> (TT2/Template ToolKit) is only required if you plan on using Handel
within TT2 based websites.

=back

=head2 Build/Test Modules

The following modules are only required for the test suite when running
C<make test>.

=over

=item Test::More

C<Test::More> version 0.48 or greater.

The C<Test::More> included with perl 5.8.4 and C<Test::More> <= 0.48 have issues
with ithreads that usually cause crashes in tests that use C<Class::DBI> or
C<DBIx:ContextualFetch>. The errors usual mention
"attempt to free unreferenced scalar". If you reveive these during C<make test>,
try upgrading C<Test::More>.

=item Pod::Coverage

C<Pod::Coverage> version 0.14 or greater.

The pod coverage tests may fail complaining about missing pod for methods if
Pod::Coverage < 0.14 is installed. This is due to certain syntax variations of
the pod with escaped gt/lt. I may just alter the pod and bump this version down
if there is enough feedback to do so.

=item Test::Pod

C<Test::Pod> version 1.00 or greater.

C<Test::Pod> 1.00 added the C<all_pod_files_ok()> method which makes my life
easier. :-)

=item Test::Pod::Coverage

C<Test::Pod::Coverage> version 1.04 or greater.

C<Test::Pod::Coverage> 1.04 was made taint safe, and we run the tests with -wT
like good girls and boys.

=item Test:Strict

C<Test::Strict> version 0.01 or greater.

This keeps me honest and makes sure I always C<use strict>.

=back

=head1 SEE ALSO

L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
