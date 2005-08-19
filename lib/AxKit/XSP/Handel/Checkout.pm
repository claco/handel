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
    my @context = 'root';

    sub start_document {
        return "use Handel::Checkout;\nuse Handel::Constants qw(:checkout);\n";
    };


    sub parse_char {
        my ($e, $text) = @_;
        my $tag = $e->current_element();

        return unless length($text);

        if ($tag eq 'addmessage') {
            return "\n\$_xsp_handel_checkout_addmessage_hash{'text'} = q|" . $text . "|;\n";
        } elsif ($tag =~ /^load(order|cart)$/) {
            return ".q|$text|";
        };

        return '';
    };

    sub parse_start {
        my ($e, $tag, %attr) = @_;

        AxKit::Debug(5, "[Handel] [Checkout] parse_start [$tag] context: " . join('->', @context));

        if ($tag eq 'new') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \$_xsp_handel_checkout;my \$_xsp_handel_checkout_status;my \$_xsp_handel_checkout_new_options;my \$_xsp_handel_checkout_new_called;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_checkout_new_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_checkout_new_filter;' ;

            return "\n{\n$code\n";
        } elsif ($tag eq 'plugins') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                foreach my $_xsp_handel_checkout_plugin ($_xsp_handel_checkout->plugins) {
            ';

            return $code;
        } elsif ($tag eq 'plugin') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] ne 'plugins');

            push @context, $tag;

            $e->start_expr($tag);
            $e->append_to_script("ref \$_xsp_handel_checkout_plugin;\n");
            $e->end_expr($tag);
        } elsif ($tag eq 'messages') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                foreach my $_xsp_handel_checkout_message ($_xsp_handel_checkout->messages) {
            ';

            return $code;
        } elsif ($tag eq 'message' || $tag =~ /^message\-(.*)$/) {
            my $property = $1;

            # I have no friggin clue how the regexp above on this tag can
            # yield checkout, but it does. :-)
            undef $property if ($property eq 'checkout');

            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] ne 'messages');

            push @context, $tag;

            $e->start_expr($tag);
            if ($property) {
                $e->append_to_script("\$_xsp_handel_checkout_message->$property;\n");
            } else {
                $e->append_to_script("\$_xsp_handel_checkout_message;\n");
            };
            $e->end_expr($tag);
        } elsif ($tag eq 'addmessage') {
            my $code = 'my $_xsp_handel_checkout_addmessage_hash;
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
            ';

            $code .= scalar keys %attr ?
                'my %_xsp_handel_checkout_addmessage_hash = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_checkout_addmessage_hash;' ;

            return "\n{\n$code\n";
        } elsif ($tag eq 'phases') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                foreach my $_xsp_handel_checkout_phase ($_xsp_handel_checkout->phases) {
            ';

            return $code;
        } elsif ($tag eq 'phase') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] ne 'phases');

            push @context, $tag;

            $e->start_expr($tag);
            $e->append_to_script("\$_xsp_handel_checkout_phase;\n");
            $e->end_expr($tag);
        } elsif ($tag eq 'process') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                $_xsp_handel_checkout_status = $_xsp_handel_checkout->process;
            ';

            return $code;
        } elsif ($tag =~ /^(ok|success(ful)?)$/) {
            push @context, $tag;

            my $code = '
                if ($_xsp_handel_checkout_status == CHECKOUT_STATUS_OK) {
            ';

            return $code;
        } elsif ($tag =~ /^(error|fail(ure)?)$/) {
            push @context, $tag;

            my $code = '
                if ($_xsp_handel_checkout_status != CHECKOUT_STATUS_OK) {
            ';

            return $code;
        } elsif ($tag eq 'loadorder') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                $_xsp_handel_checkout->order(\'\'';

            return $code;
        } elsif ($tag eq 'loadcart') {
            push @context, $tag;

            my $code = '
                if (!$_xsp_handel_checkout_new_called) {
                    $_xsp_handel_checkout = Handel::Checkout->new(\%_xsp_handel_checkout_new_filter);
                    $_xsp_handel_checkout_new_called++;
                };
                $_xsp_handel_checkout->cart(\'\'';

            return $code;
        };

        return '';
    };

    sub parse_end {
        my ($e, $tag) = @_;

        AxKit::Debug(5, "[Handel] [Checkout] parse_end   [$tag] context: " . join('->', @context));

        if ($tag eq 'new') {
            pop @context;

            return "\n};\n";
        } elsif ($tag eq 'plugins') {
            pop @context;

            return '
                };
            ';
        } elsif ($tag eq 'plugin') {
            pop @context;
        } elsif ($tag eq 'messages') {
            pop @context;

            return '
                };
            ';
        } elsif ($tag eq 'message' || $tag =~ /^message-(.*)$/) {
            pop @context;
        } elsif ($tag eq 'addmessage') {
            return '
                    $_xsp_handel_checkout->add_message(Handel::Checkout::Message->new(%_xsp_handel_checkout_addmessage_hash));
                };
            ';
        } elsif ($tag eq 'phases') {
            pop @context;

            return '
                };
            ';
        } elsif ($tag eq 'phase') {
            pop @context;
        } elsif ($tag eq 'process') {
            pop @context;
        } elsif ($tag =~ /^(ok|success(ful)?)$/) {
            pop @context;

            my $code = '
                };
            ';

            return $code;
        } elsif ($tag =~ /^(error|fail(ure)?)$/) {
            pop @context;

            my $code = '
                };
            ';

            return $code;
        } elsif ($tag eq 'loadorder') {
            pop @context;

            my $code = ');
            ';

            return $code;
        } elsif ($tag eq 'loadcart') {
            pop @context;

            my $code = ');
            ';

            return $code;
        };

        return '';
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

=head1 TAG HIERARCHY

    <checkout:new pluginpaths|addpluginpaths|loadplugins|ignoreplugins|order|cart|="value"...>

    </checkout:new>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
