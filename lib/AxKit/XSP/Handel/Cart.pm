# $Id$
package AxKit::XSP::Handel::Cart;
use warnings;
use strict;
use Apache::AxKit::Language::XSP;
use vars qw(@ISA $NS);

@ISA = ('Apache::AxKit::Language::XSP');
$NS  = 'http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Cart';

my @context;

sub start_document {
   return "use Handel::Cart;\n";
};

sub parse_char {
    my ($e, $text) = @_;

    ## bail if we're in elemnts in add/update not in cart
    if ($context[$#context] =~ /^(add|update)$/ && $context[$#context-1] ne 'cart') {
        return '';
    };

    ## bail if we're in clear or save
    return '' if($e->current_element =~ /^(clear|save)$/);

    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    return ". q|$text|";
};

sub parse_start {
    my ($e, $tag, %attr) = @_;

    AxKit::Debug(5, __PACKAGE__ . "::parse_start tag=$tag, attr=" . join(',', %
    attr));
    AxKit::Debug(5, __PACKAGE__ . "::parse_start context=" .
    join(',',@context));

    ## cart:load
    if ($tag eq 'load') {
        die "$tag must be toplevel" unless (!@context);
        push @context, $tag;

        $e->manage_text(0);

        my $code = (scalar %attr) ?
            '{
                my %_xsp_handel_cart_load_filter = ("'.join('", "', %attr).'");
            ' :
            '{
                my %_xsp_handel_cart_load_filter;
            ';

        $code .=
            '
                my ($_xsp_handel_cart_loaded,
                @_xsp_handel_cart_carts,$_xsp_handel_cart_cart);
            ';

        return $code;
    } elsif ($tag eq 'new') {
        die "$tag must be toplevel" unless (!@context);
        push @context, $tag;

        $e->manage_text(0);

        my $code = (scalar %attr) ?
            '{
                my %_xsp_handel_cart_new_filter = ("'.join('", "', %attr).'");
            ' :
            '{
                my %_xsp_handel_cart_new_filter;
            ';
        return $code;
    ## cart:filter
    } elsif ($tag eq 'filter') {
        return '' unless $attr{name};

        if ($context[$#context] eq 'delete' && $context[$#context-1] eq 'cart') {
            return '$_xsp_handel_cart_delete_filter{\''.$attr{name}.'\'} =
            \'\'';
        } else {
            return '$_xsp_handel_cart_load_filter{\''.$attr{name}.'\'} = \'\'';
        };

    ## cart:carts, cart
    } elsif ($tag =~ /^cart(s?)$/) {
        push @context, $tag;

        $e->manage_text(0);

        my $code = '
            if (!$_xsp_handel_cart_loaded) {

                @_xsp_handel_cart_carts = (scalar keys %_xsp_handel_cart_load_filter) ?
                    Handel::Cart->load(\%_xsp_handel_cart_load_filter) :
                    Handel::Cart->load();

                $_xsp_handel_cart_loaded = 1;
            };'."\n";

        if ($tag eq 'carts') {
            $code .= '
                foreach $_xsp_handel_cart_cart (@_xsp_handel_cart_carts) {
            ';
        } elsif ($tag eq 'cart') {
            $code .= '
                $_xsp_handel_cart_cart = shift(@_xsp_handel_cart_carts);
                if ($_xsp_handel_cart_cart) {
            ';
        };
        return $code;

    ## cart:shopper, name, subtotal, type, count
    } elsif ($tag =~ /^(shopper|name|subtotal|type|count)$/) {
        if ($context[$#context] eq 'update') {
            die "$tag not supported in update" if ($tag =~ /^(subtotal|count)$/);
            return "
                \$_xsp_handel_cart_cart->$tag(''
            ";
        } elsif ($context[$#context] eq 'new') {
            die "$tag not supported in new" if ($tag =~ /^(subtotal|count)$/);
            return "\$_xsp_handel_cart_new_filter{'$tag'} = ''";
        } else {
            $e->start_expr($tag);
            $e->append_to_script("no strict 'vars';if (\$_xsp_handel_cart_cart){\$_xsp_handel_cart_cart->$tag}");
        };
    ## cart:items
    } elsif ($tag eq 'items') {
        push @context, $tag;

        return '
            if ($_xsp_handel_cart_cart) {
                my @_xsp_handel_cart_items = $_xsp_handel_cart_cart->items;
                foreach my $_xsp_handel_cart_item (@_xsp_handel_cart_items) {
        ';

    ## cart:sku, quantity, total, price
    } elsif ($tag =~ /^(sku|quantity|total|price)$/) {
        if ($context[$#context] eq 'add' && $context[$#context-1] eq 'cart') {
            return "\$_xsp_handel_cart_add_filter{'$tag'} = ''";
        } elsif ($context[$#context] eq 'add' && $context[$#context-1] ne
        'cart') {
            return '';
        } else {
            $e->start_expr($tag);
            $e->append_to_script("no strict 'vars';if (\$_xsp_handel_cart_item){\$_xsp_handel_cart_item->$tag}");
        };

    ## cart:id, description
    } elsif ($tag =~ /^(id|description)$/) {
        if ($context[$#context] =~ /^cart(s?)$/) {
            $e->start_expr($tag);
            $e->append_to_script("no strict 'vars';if (\$_xsp_handel_cart_cart){\$_xsp_handel_cart_cart->$tag}");
        } elsif ($context[$#context] eq 'items') {
            $e->start_expr($tag);
            $e->append_to_script("no strict 'vars';if (\$_xsp_handel_cart_item){\$_xsp_handel_cart_item->$tag}");
        } elsif ($context[$#context] eq 'add' && $context[$#context-1] eq 'cart') {
            return "\$_xsp_handel_cart_add_filter{'$tag'} = ''";
        } elsif ($context[$#context] eq 'update' && $context[$#context-1] eq 'cart') {
            die "$tag not supported in update" if ($tag eq 'id');
            return "
                \$_xsp_handel_cart_cart->$tag(''
            ";
        } elsif ($context[$#context] eq 'new') {
            return "\$_xsp_handel_cart_new_filter{'$tag'} = ''";
        };

    ## cart:add
    } elsif ($tag eq 'add') {
        push @context, $tag;

        $e->manage_text(0);

        if ($context[$#context-1] eq 'cart') {
        my $code = (scalar %attr) ?
                '{
                    my %_xsp_handel_cart_add_filter = ("'.join('", "', %attr).'");
                ' :
                '{
                    my %_xsp_handel_cart_add_filter;
                ';
            return $code;
        };
    } elsif ($tag eq 'clear') {
        if ($context[$#context] eq 'cart') {
            return '
                if ($_xsp_handel_cart_cart) {
                    $_xsp_handel_cart_cart->clear;
                };
            ';
        };
    } elsif ($tag eq 'save') {
        if ($context[$#context] eq 'cart') {
            return '
                if ($_xsp_handel_cart_cart) {
                    $_xsp_handel_cart_cart->save;
                };
            ';
        };
    } elsif ($tag eq 'delete') {
        push @context, $tag;

        $e->manage_text(0);

        if ($context[$#context-1] eq 'cart') {
            my $code = (scalar %attr) ?
                '{
                    my %_xsp_handel_cart_delete_filter = ("'.join('", "', %attr).'");
                ' :
                '{
                    my %_xsp_handel_cart_delete_filter;
                ';
            return $code;
        };
    } elsif ($tag eq 'update') {
        push @context, $tag;

        $e->manage_text(0);

        if ($context[$#context-1] eq 'cart') {
            return '
               if ($_xsp_handel_cart_cart) {
            ';
        };
    };

    return '';
};

sub parse_end {
    my ($e, $tag) = @_;

    AxKit::Debug(5, __PACKAGE__ . "::parse_end   tag=$tag");
    AxKit::Debug(5, __PACKAGE__ . "::parse_end   context=" .
    join(',',@context));

    ## cart:load
    if ($tag eq 'load') {
        pop @context;

        return "\n};\n";

    } elsif ($tag eq 'new') {
        pop @context;

        return '
            if (scalar keys %_xsp_handel_cart_new_filter) {
                Handel::Cart->new(\%_xsp_handel_cart_new_filter);
            };
        };
        ';

    ## cart:filter
    } elsif ($tag eq 'filter') {
        return ";\n";

    ## cart:carts, cart
    } elsif ($tag =~ /^cart(s?)$/) {
        pop @context;

        if ($tag eq 'carts') {
            return "\n};\n";
        } elsif ($tag eq 'cart') {
            return "\n};\n";
        };


    ## cart:shopper, name, subtotal, type, count
    } elsif ($tag =~ /^(shopper|name|subtotal|type|count)$/) {
        if ($context[$#context] eq 'update') {
            return ');
            ';
        } elsif ($context[$#context] eq 'new') {
            return ';
            ';
        } else {
            $e->end_expr($tag);
        };
    ## cart:items
    } elsif ($tag eq 'items') {
        pop @context;

        return "\n};\n};\n";

    ## cart:sku, quantity, total, price
    } elsif ($tag =~ /^(sku|quantity|total|price)$/) {
        if ($context[$#context] eq 'add' && $context[$#context-1] eq 'cart') {
            return ";\n";
        } elsif ($context[$#context] eq 'add' && $context[$#context-1] ne 'cart') {
            return '';
        } else {
            $e->end_expr($tag);
        };
    ## cart:id, description
    } elsif ($tag =~ /^(id|description)$/) {
        if ($context[$#context] eq 'add' && $context[$#context-1] eq 'cart') {
            return ";\n";
        } elsif ($context[$#context] eq 'update' && $context[$#context-1] eq 'cart') {
            return ");\n";

        } elsif ($context[$#context] eq 'add' && $context[$#context-1] ne 'cart') {
            return '';
        } elsif ($context[$#context] eq 'new') {
            return ";\n";
        } else {
            $e->end_expr($tag);
        };

    ## cart:add
    } elsif ($tag eq 'add') {
        if ($context[$#context-1] eq 'cart') {
            pop @context;
            return '
                if (scalar keys %_xsp_handel_cart_add_filter && $_xsp_handel_cart_cart) {
                    $_xsp_handel_cart_cart->add(\%_xsp_handel_cart_add_filter);
                };
            };
            ';
        };

        pop @context;
    } elsif ($tag eq 'delete') {
        if ($context[$#context-1] eq 'cart') {
            pop @context;
            return '
                if (scalar keys %_xsp_handel_cart_delete_filter && $_xsp_handel_cart_cart) {
                    $_xsp_handel_cart_cart->delete(\%_xsp_handel_cart_delete_filter);
                };
            };
            ';
        };

        pop @context;
    } elsif ($tag eq 'update') {
        if ($context[$#context-1] eq 'cart') {
            pop @context;
            return '
                };
            ';
        };

        pop @context;
    };

    return '';
};

1;
__END__

=head1 NAME

AxKit::XSP::Handel::Cart - XSP Cart Taglib

=head1 SYNOPSIS

    ...xmlns:cart="http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Cart"...

    <cart:load type="1">
        <cart:filter name="id"><request:idparam/></cart:filter>

        <cart:cart>
            <cart>
                <id><cart:id/></id>
                <name><cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>

                <cart:items>
                    <item>
                        <sku><cart:sku/></sku>
                        <description><cart:description/></description>
                        <quantity><cart:quantity/></quantity>
                        <price><cart:price/></price>
                        <total><cart:total/></total>
                    </item>
                </cart:items>
            </cart>
        </cart:cart>
    </cart:load>

=head1 DESCRIPTION

=head1 TAGS

=head2 C<<cart:new>>

=head2 C<<cart:load>>

=head2 C<<cart:add>>

=head2 C<<cart:update>>



=head2 C<<cart:clear>>

=head2 C<<cart:filter>>

=head2 C<<cart:carts>>

=head2 C<<cart:cart>>

=head2 C<<cart:items>>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/



