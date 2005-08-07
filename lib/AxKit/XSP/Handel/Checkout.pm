# $Id$
package AxKit::XSP::Handel::Checkout;
use strict;
use warnings;
use vars qw($NS);
use Handel::ConfigReader;
use Handel::Constants qw(:checkout str_to_const);
use Handel::Exception;
use Handel::L10N qw(translate);
use base 'Apache::AxKit::Language::XSP';

$NS  = 'http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Checkout';

{
 sub parse_char {

 };
};

1;
__END__

=head1 NAME

AxKit::XSP::Handel::Checkout - AxKit XSP Checkout Taglib

=head1 SYNOPSIS

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::Handel::Checkout

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:checkout="http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Checkout"
    >

=head1 DESCRIPTION

This tag library provides an interface to use C<Handel::Checkout> inside of your
AxKit XSP pages.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
