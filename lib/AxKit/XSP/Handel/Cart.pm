# $Id$
package AxKit::XSP::Handel::Cart;
use strict;
use warnings;
use vars qw($NS);
use Handel::Exception;
use Handel::L10N qw(translate);
use base 'Apache::AxKit::Language::XSP';

$NS  = 'http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Cart';

{
    my @context = 'root';

    sub start_document {
        return "use Handel::Cart;\n";
    };

    sub parse_char {
        my ($e, $text) = @_;
        my $tag = $e->current_element();

        if ($tag =~ /^(description|id|name|shopper|type)$/) {
            if ($context[$#context] eq 'new') {
                return "q|$text|";
            } elsif ($context[$#context] eq 'new') {
                return "q|$text|";
            } elsif ($context[$#context] eq 'add') {
                return "q|$text|";
            } elsif ($context[$#context] eq 'delete') {
                return "q|$text|";
            };
        } elsif ($tag =~ /^(sku|price|quantity)$/) {
            if ($context[$#context] eq 'add') {
                return "q|$text|";
            } elsif ($context[$#context] eq 'delete') {
                return "q|$text|";
            };
        } elsif ($tag eq 'filter') {
            return "q|$text|";
        };
        return '';
    };

    sub parse_start {
        my ($e, $tag, %attr) = @_;

        AxKit::Debug(5, "[Handel] parse_start [$tag] context: " . join('->', @context));

        ## cart:new
        if ($tag eq 'new') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_cart;\nmy \$_xsp_handel_cart_called_new;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_new_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_new_filter;' ;

            return "\n{\n$code\n";


        ## cart:cart
        } elsif ($tag eq 'cart') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_cart;\nmy \$_xsp_handel_cart_called_load;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_load_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_load_filter;' ;

            return "\n{\n$code\n";


        ## cart:item
        } elsif ($tag eq 'item') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] =~ /^(cart(s?))$/);

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_item;\nmy \$_xsp_handel_cart_called_item;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_item_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_item_filter;' ;

            return "\n{\n$code\n";


        ## cart:items
        } elsif ($tag eq 'items') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] =~ /^(cart(s?))$/);

            push @context, $tag;

            my $code = "my \@_xsp_handel_cart_items;\nmy \$_xsp_handel_cart_called_items;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_items_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_items_filter;' ;

            return "\n{\n$code\n";


        ## cart:clear
        } elsif ($tag eq 'clear') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(cart(s?))$/);

           return "\nwarn 'clearing';\$_xsp_handel_cart_cart->clear;\n";


        ## cart:add
        } elsif ($tag eq 'add') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(new|cart)$/);

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_item;\nmy \$_xsp_handel_cart_called_add;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_add_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_add_filter;' ;

            return "\n{\n$code\n";


        ## cart:delete
        } elsif ($tag eq 'delete') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(cart(s?))$/);

            push @context, $tag;

            my $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_delete_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_delete_filter;' ;

            return "\n{\n$code\n";


        ## cart property tags
        ## cart:description, id, name, shopper, type, count, subtotal
        } elsif ($tag =~ /^(description|id|name|shopper|type|count|subtotal)$/) {
            if ($context[$#context] eq 'new' && $tag !~ /^(count|subtotal)$/) {
                return "\n\$_xsp_handel_cart_new_filter{$tag} = ";
            } elsif ($context[$#context] eq 'add' && $tag =~ /^(id|description)$/) {
                return "\n\$_xsp_handel_cart_add_filter{$tag} = ";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'new') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_cart->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'cart') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_cart->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'item') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'items') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return "\n\$_xsp_handel_cart_delete_filter{$tag} = ";
            };


        ## cart item property tags
        ## cart:sku, price, quantity, total
        } elsif ($tag =~ /^(sku|price|quantity|total)$/) {
            if ($context[$#context] eq 'add' && $tag ne 'total') {
                return "\n\$_xsp_handel_cart_add_filter{$tag} = ";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'item') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'items') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'delete') {
                return "\n\$_xsp_handel_cart_delete_filter{$tag} = ";
            };


        ## cart:filter
        } elsif ($tag eq 'filter') {
            my $key = $attr{'name'} || 'id';

            if ($context[$#context] eq 'cart') {
                return "\n\$_xsp_handel_cart_load_filter{'$key'} = ";
            } elsif ($context[$#context] eq 'item') {
                return "\n\$_xsp_handel_cart_item_filter{'$key'} = ";
            } elsif ($context[$#context] eq 'items') {
                return "\n\$_xsp_handel_cart_items_filter{'$key'} = ";
            };


        ## cart:results
        } elsif ($tag eq 'results') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] !~ /^(new|add|cart(s?)|item(s?))$/);

            push @context, $tag;

            if ($context[$#context-1] eq 'new') {
                return '
                    if (!$_xsp_handel_cart_called_new && scalar keys %_xsp_handel_cart_new_filter) {
                        $_xsp_handel_cart_cart = Handel::Cart->new(\%_xsp_handel_cart_new_filter);
                        $_xsp_handel_cart_called_new = 1;
                    };
                    if ($_xsp_handel_cart_cart) {

                ';
            } elsif ($context[$#context-1] eq 'cart') {
                return '
                    if (!$_xsp_handel_cart_called_load) {
                        $_xsp_handel_cart_cart = (scalar keys %_xsp_handel_cart_load_filter) ?
                            Handel::Cart->load(\%_xsp_handel_cart_load_filter, 1)->next :
                            Handel::Cart->load(undef, 1)->next;
                            $_xsp_handel_cart_called_load = 1;
                    };
                    if ($_xsp_handel_cart_cart) {

                ';
            } elsif ($context[$#context-1] eq 'item') {
                return '
                    if (!$_xsp_handel_cart_called_item) {
                        $_xsp_handel_cart_item = (scalar keys %_xsp_handel_cart_item_filter) ?
                            $_xsp_handel_cart_cart->items(\%_xsp_handel_cart_item_filter, 1)->next :
                            $_xsp_handel_cart_cart->items(undef, 1)->next;
                            $_xsp_handel_cart_called_item = 1;
                    };
                    if ($_xsp_handel_cart_item) {

                ';
            } elsif ($context[$#context-1] eq 'items') {
                return '
                    if (!$_xsp_handel_cart_called_items) {
                        @_xsp_handel_cart_items = (scalar keys %_xsp_handel_cart_items_filter) ?
                            $_xsp_handel_cart_cart->items(\%_xsp_handel_cart_items_filter) :
                            $_xsp_handel_cart_cart->items();
                            $_xsp_handel_cart_called_items = 1;
                    };
                    foreach my $_xsp_handel_cart_item (@_xsp_handel_cart_items) {

                ';
            } elsif ($context[$#context-1] eq 'add') {
                return '
                    if (!$_xsp_handel_cart_called_add && scalar keys %_xsp_handel_cart_add_filter) {
                        $_xsp_handel_cart_item = $_xsp_handel_cart_cart->add(\%_xsp_handel_cart_add_filter);
                        $_xsp_handel_cart_called_add = 1;
                    };
                    if ($_xsp_handel_cart_item) {

                ';
            };


        ## cart:no-results
        } elsif ($tag eq 'no-results') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] !~ /^(new|add|cart(s?)|item(s?))$/);

            push @context, $tag;

            if ($context[$#context-1] eq 'new') {
                return '
                    if (!$_xsp_handel_cart_called_new && scalar keys %_xsp_handel_cart_new_filter) {
                        $_xsp_handel_cart_cart = Handel::Cart->new(\%_xsp_handel_cart_new_filter);
                        $_xsp_handel_cart_called_new = 1;
                    };
                    if (!$_xsp_handel_cart_cart) {
                ';
            } elsif ($context[$#context-1] eq 'cart') {
                return '
                    if (!$_xsp_handel_cart_called_load) {
                        $_xsp_handel_cart_cart = (scalar keys %_xsp_handel_cart_load_filter) ?
                            Handel::Cart->load(\%_xsp_handel_cart_load_filter, 1)->next :
                            Handel::Cart->load(undef, 1)->next;
                            $_xsp_handel_cart_called_load = 1;
                    };
                    if (!$_xsp_handel_cart_cart) {
                ';
            } elsif ($context[$#context-1] eq 'item') {
                return '
                    if (!$_xsp_handel_cart_called_item) {
                        $_xsp_handel_cart_item = (scalar keys %_xsp_handel_cart_item_filter) ?
                            $_xsp_handel_cart_cart->items(\%_xsp_handel_cart_item_filter, 1)->next :
                            $_xsp_handel_cart_cart->items(undef, 1)->next;
                            $_xsp_handel_cart_called_item = 1;
                    };
                    if (!$_xsp_handel_cart_item) {
                ';
            } elsif ($context[$#context-1] eq 'items') {
                return '
                    if (!$_xsp_handel_cart_called_items) {
                        @_xsp_handel_cart_items = (scalar keys %_xsp_handel_cart_items_filter) ?
                            $_xsp_handel_cart_cart->items(\%_xsp_handel_cart_items_filter) :
                            $_xsp_handel_cart_cart->items();
                            $_xsp_handel_cart_called_items = 1;
                    };
                    if (!scalar @_xsp_handel_cart_items) {
                ';
            } elsif ($context[$#context-1] eq 'add') {
                return '
                    if (!$_xsp_handel_cart_called_add && scalar keys %_xsp_handel_cart_add_filter) {
                        $_xsp_handel_cart_item = $_xsp_handel_cart_cart->add(\%_xsp_handel_cart_add_filter);
                        $_xsp_handel_cart_called_add = 1;
                    };
                    if (!$_xsp_handel_cart_item) {
                ';
            };
        };

        return '';
    };

    sub parse_end {
        my ($e, $tag) = @_;

        AxKit::Debug(5, "[Handel] parse_end [$tag] context: " . join('->', @context));

        ## cart:new
        if ($tag eq 'new') {
            pop @context;

            return '
                if (!$_xsp_handel_cart_called_new && scalar keys %_xsp_handel_cart_new_filter) {
                    $_xsp_handel_cart_cart = Handel::Cart->new(\%_xsp_handel_cart_new_filter);
                    $_xsp_handel_cart_called_new = 1;
                };
            };';


        ## cart:cart
        } elsif ($tag eq 'cart') {
            pop @context;

            return "\n};\n";


        ## cart:item
        } elsif ($tag eq 'item') {
            pop @context;

            return "\n};\n";


        ## cart:items
        } elsif ($tag eq 'items') {
            pop @context;

            return "\n};\n";


        ## cart:add
        } elsif ($tag eq 'add') {
            pop @context;

            return '
                if (!$_xsp_handel_cart_called_add && scalar keys %_xsp_handel_cart_add_filter) {
                    $_xsp_handel_cart_item = $_xsp_handel_cart_cart->add(\%_xsp_handel_cart_add_filter);
                    $_xsp_handel_cart_called_add = 1;
                };
            };
            ';


        ## cart:delete
        } elsif ($tag eq 'delete') {
            pop @context;

            return '
                if (scalar keys %_xsp_handel_cart_delete_filter) {
                    $_xsp_handel_cart_cart->delete(\%_xsp_handel_cart_delete_filter);
                };
            };
            ';

        ## cart propery tags
        ## cart:description, id, name, shopper, type, count, subtotal
        } elsif ($tag =~ /^(description|id|name|shopper|type|count|subtotal)$/) {
            if ($context[$#context] eq 'new' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'add' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'results') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            };


        ## cart item property tags
        ## cart:sku, price, quantity
        } elsif ($tag =~ /^(sku|price|quantity|total)$/) {
            if ($context[$#context] eq 'add' && $tag ne 'total') {
                return ";\n";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'item') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'items') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            };


        ## cart:filter
        } elsif ($tag eq 'filter') {
            if ($context[$#context] eq 'cart') {
                return ";\n";
            } elsif ($context[$#context] eq 'item') {
                return ";\n";
            } elsif ($context[$#context] eq 'items') {
                return ";\n";
            };


        ## cart:results
        } elsif ($tag eq 'results') {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'cart') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'item') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'items') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'add') {
                pop @context;

                return "\n};\n";
            };
            pop @context;


        ## cart:no-results
        } elsif ($tag eq 'no-results') {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'cart') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'item') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'items') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'add') {
                pop @context;

                return "\n};\n";
            };
            pop @context;
        };

        return '';
    };
};

1;
__END__

=head1 NAME

AxKit::XSP::Handel::Cart - XSP Cart Taglib

=head1 SYNOPSIS

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::Handel::Cart

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:cart="http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Cart"
    >

    <cart:cart type="1">
        <cart:filter name="id"><request:idparam/></cart:filter>
        <cart:results>
            <cart>
                <id><cart:id/></id>
                <name><cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>
                <cart:items>
                    <cart:results>
                        <item>
                            <sku><cart:sku/></sku>
                            <description><cart:description/></description>
                            <quantity><cart:quantity/></quantity>
                            <price><cart:price/></price>
                            <total><cart:total/></total>
                        </item>
                    </cart:results>
                    </cart:no-results>
                        <message>There are currently no items in your shopping cart.</message>
                    </cart:no-results>
                </cart:items>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head1 DESCRIPTION

This tag library provides an interface to use L<Handel::Cart> inside of your
AxKit XSP pages.

=head1 TAG HIERARCHY

    <cart:new description|id|name|shopper|type="value"...>
        <cart:description>value</cart:description>
        <cart:id>value</cart:id>
        <cart:name>value</cart:name>
        <cart:shopper>value</cart:shopper>
        <cart:type>value</cart:type>
        <cart:results>
            <cart:count/>
            <cart:description/>
            <cart:id/>
            <cart:name/>
            <cart:shopper/>
            <cart:subtotal/>
            <cart:type/>
            <cart:add id|sku|quantity|price|description="value"...>
                <cart:description>value</cart:description>
                <cart:id>value</cart:id>
                <cart:sku>value</cart:sku>
                <cart:quantity>value</cart:quantity>
                <cart:price>value</cart:price>
                <cart:results>
                    <cart:description/>
                    <cart:id/>
                    <cart:price/>
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total/>
                </cart:results>
                <cart:no-results>
                    ...
                </cart:no-results>
            </cart:add>
        </cart:results>
        <cart:no-results>
            ...
        <cart:no-results>
    </cart:new>
    <cart:cart(s) description|id|name|shopper|type="value"...>
        <cart:filter name="description|id|name|shopper|type">value</cart:filter>
        <cart:results>
            <cart:add description|id|price|quantity|sku="value"...>
                <cart:description>value</cart:description>
                <cart:id>value</cart:id>
                <cart:price>value</cart:price>
                <cart:quantity>value</cart:quantity>
                <cart:sku>value</cart:sku>
                <cart:results>
                    <cart:description/>
                    <cart:id/>
                    <cart:price/>
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total/>
                </cart:results>
                </cart:no-results>
                    ...
                </cart:no-results>
            </cart:add>
            <cart:clear/>
            <cart:count/>
            <cart:delete description|id|price|quantity|sku="value"...>
                <cart:description>value</cart:description>
                <cart:id>value</cart:id>
                <cart:price>value</cart:price>
                <cart:quantity>value</cart:quantity>
                <cart:sku>value</cart:sku>
            </cart:delete>
            <cart:description/>
            <cart:id/>
            <cart:item(s) description|id|price|quantity|sku="value"...>
                <cart:filter name="description|id|price|quantity|sku">value</cart:filter>
                <cart:results>
                    <cart:description/>
                    <cart:id/>
                    <cart:price/>
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total/>
                    <cart:update>
                        <cart:description>value</cart:description>
                        <cart:price>value</cart:price>
                        <cart:quantity>value</cart:quantity>
                        <cart:sku>value</cart:sku>
                    </cart:update>
                </cart:results>
                <cart:no-results>
                    ...
                </cart:no-results>
            </cart:item(s)>
            <cart:name/>
            <cart:save/>
            <cart:subtotal/>
            <cart:type/>
            <cart:update>
                <cart:description></cart:description>
                <cart:name></cart:name>
                <cart:shopper></cart:shopper>
                <cart:type></cart:type>
            </cart:update>
        </cart:results>
        <cart:no-results>
            ...
        </cart:no-results>
    </cart:cart(s)>

=head1 TAG REFERENCE

=head2 C<E<lt>cart:addE<gt>>

Adds an a item to the current cart. You can specify the item properties as
attributes in the tag itself:

    <cart:add
        description="My New Part"
        id="11111111-1111-1111-1111-111111111111"
        sku="1234"
        quantity="1"
        price="1.23"
    />

or you can add them as child elements:

    <cart:add>
        <cart:description>My New Part</cart:description>
        <cart:id>11111111-1111-1111-1111-111111111111</cart:id>
        <cart:sku>1234</cart:sku>
        <cart:quantity>1</cart:quantity>
        <cart:price>1.23</cart:price>
    </cart:add>

or any combination of the two:

    <cart:add quantity="1">
        <cart:description>My New Part</cart:description>
        <cart:id>11111111-1111-1111-1111-111111111111</cart:id>
        <cart:sku>1234</cart:sku>
        <cart:price>1.23</cart:price>
    </cart:add>

This tag is only valid within the C<E<lt>cart:cartE<gt>> block. See
L<Handel::Cart> for more information about adding parts to the shopping cart.

=head2 C<E<lt>cart:cartE<gt>>

Container tag for the current cart used to load a specific cart.

If C<cart> or it's C<filter>s load more than one cart, C<cart> will contain only
the first cart. If you're looking for loop through multiple carts, try
C<E<lt>cart:cartsE<gt>> instead.

    <cart:cart type="1">
        <cart:filter name="id">11111111-1111-1111-1111-111111111111</cart:filter>
        <cart:results>
            <cart>
                <id><cart:id/></id>
                <name><<cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>
                <cart:items>
                    ...
                </cart:items>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:cartsE<gt>>

Loops through all loaded carts.

        <cart:carts type="1">
            <cart:filter name="shopper">11111111-1111-1111-1111-111111111111</cart:filter>
            <cart:results>
                <cart>
                    <id><cart:id/></id>
                    <name><<cart:name/></name>
                    <description><cart:description/></description>
                    <subtotal><cart:subtotal/></subtotal>
                    <cart:items>
                        ...
                    </cart:items>
                </cart>
            </cart:results>
            <cart:no-results>
                <message>No carts were found matching your query.</message>
            </cart:no-results>
        </cart:carts>
    </carts>

=head2 C<E<lt>cart:clearE<gt>>

Deletes all items in the current shopping cart.

    <cart:cart type="0">
        <cart:filter name="shopper">11111111-1111-1111-1111-111111111111</cart:filter>
        <cart:results>
            <cart:clear/>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:countE<gt>>

Returns the number of items in the current shopping cart.

    <cart:cart>
        <cart:results>
            <cart>
                <id><cart:id/></id>
                <name><<cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>
                <count>cart:count/></count>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:descriptionE<gt>>

Context aware tag to get or set the description of various other parent tags.
Within C<E<lt>cart:cartE<gt>> or C<E<lt>cart:cartsE<gt>> it returns the current
carts description:

    <cart:cart>
        <cart:results>
            <description><cart:description/></description>
        </cart:results>
    </cart:cart>

Within C<E<lt>cart:addE<gt>> or C<E<lt>cart:updateE<gt>> it sets the current cart
or cart items description:

    <cart:cart>
        <cart:results>
            <cart:update>
                <cart:description>My Updated Cart Description</cart:description>
            </cart:update>

            <cart:add>
                <cart:description>My New SKU Description</cart:description>
            </cart:add>

            <cart:item sku="1234">
                <cart:results>
                    <cart:update>
                        <cart:description>My Updated SKU Description</cart:description>
                    <cart:update>
                </cart:results>
                <cart:no-results>
                    <message>The cart item could not be found for updating</message>
                </cart:no-results>
            <cart:item>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:filterE<gt>>

Adds a new name/value pair to the filter used in C<E<lt>cart:cartE<gt>>, C<E<lt>cart:cartsE<gt>>
C<E<lt>cart:deleteE<gt>>, C<E<lt>cart:itemE<gt>>, and C<E<lt>cart:itemsE<gt>>. Pass the
name of the pair in the C<name> atttribute and the value between the start and end filter tags:

    <cart:cart type="0">
        <cart:filter name="id">12345678-9098-7654-3212-345678909876</cart:filter>

        <cart:results>
            <cart:delete>
                <cart:filter name="sku">sku1234</cart:filter>
            <cart:delete>
        </cart:results>
        <cart:no-results>
            <message>The cart item could not be found for deletion</message>
        </cart:no-results>
    </cart:cart>

If the same attribute is specified in a filter, the filter takes precedence over
the parent tags attribute.

    <cart:cart type="0">
        <!-- type == 0 -->
        <cart:filter name="type">1</cart:filter>
        <!-- type == 1 -->
    </cart:cart>

You can supply as many C<filter>s as needed to get the job done.

    <cart:cart>
        <cart:filter name="type">0</cart:filter>
        <cart:filter name="shopper">12345678-9098-7654-3212-345678909876</cart:filter>
    </cart:cart>

=head2 C<E<lt>cart:idE<gt>>

Context aware tag to get or set the record id within various other tags. In C<E<lt>cart:cartE<gt>>
and C<E<lt>cart:itemE<gt>> it returns the record id for the object:

    <cart:cart>
        <cart:results>
            <id><cart:id/></id>
            <cart:items>
                <cart:cart:results>
                    <item>
                        <id><cart:id/></id>
                    </item>
                </cart:results>
            </cart:items>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

Within C<E<lt>cart:addE<gt>>, C<E<lt>cart:deleteE<gt>>, and C<E<lt>cart:newE<gt>>
it sets the id value used in the operation specified:

    <cart:cart>
        <cart:results>
            <cart:delete>
                <cart:id>11111111-1111-1111-1111-111111111111</cart:id>
            </cart:delete>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>
    ...
    <cart:new>
        <cart:id>11112222-3333-4444-5555-6666777788889999</cart:id>
        <cart:name>New Cart</cart:name>
    </cart:new>

It cannot be used within C<E<lt>cart:updateE<gt>> and will C<die> if you try updating
the record ids which are the primary keys.

=head2 C<E<lt>cart:itemsE<gt>>

Loops through all items in the current cart:

    <cart:cart>
        <cart:results>
            <cart>
                <cart:items>
                    <cart:results>
                        <item>
                            <sku><cart:sku/></sku>
                            <description><cart:description/></cart:description>
                            <sku><cart:sku/></sku>
                            <quantity><cart:quantity/></quantity>
                            <price><cart:price/></price>
                            <total><cart:total/></total>
                        </item>
                    </cart:results>
                    <cart:no-results>
                        <message>Your shopping cart is empty</message>
                    </cart:no-results>
                </cart:items>
            <cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:nameE<gt>>

Context aware tag to get or set the name within various other tags. In C<E<lt>cart:cartE<gt>>
it returns the name for the cart object:

    <cart:cart>
        <cart:results>
            <name><cart:name/></name>
            ...
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

Within C<E<lt>cart:updateE<gt>> and C<E<lt>cart:newE<gt>> it sets the name value
used in the operation specified:

    <cart:cart>
        <cart:results>
            <cart:update>
                <cart:name>My Updated Cart Name</cart:name>
            </cart:update>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>
    ...
    <cart:new>
        <cart:name>New Cart</cart:name>
    </cart:new>

=head2 C<E<lt>cart:newE<gt>>

Creates a new shopping cart using the supplied attributes and child tags:

    <cart:new type="1">
        <cart:id>22222222-2222-2222-2222-222222222222</cart:id>
        <cart:shopper><request:shopper/></cart:shopper>
        <cart:name>New Cart</cart:name>
    </cart:new>

The child tags take precedence over the attributes of the same name.
C<new> B<must be a top level tag> within it's declared namespace. It will C<die> otherwise.

=head2 C<E<lt>cart:priceE<gt>>

Context aware tag to get or set the price of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the price:

    <cart:cart>
        <cart:results>
            <cart:add>
                <cart:price>1.24</cart:price>
            </cart:add>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the price for the cart item:

    <cart:cart>
        <cart:results>
            <cart>
                <cart:items>
                    <cart:results>
                        <item>
                            <price><cart:price/></price>
                        </item>
                    </cart:results>
                    <cart:no-results>
                        <message>Your shopping cart is empty</message>
                    </cart:no-results>
                </cart:items>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:quantityE<gt>>

Context aware tag to get or set the quantity of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the quantity:

    <cart:cart>
        <cart:results>
            <cart:add>
                <cart:quantity>1.24</cart:quantity>
            </cart:add>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the quantity for the cart item:

    <cart:cart>
        <cart:results>
            <cart>
                <cart:items>
                    <cart:results>
                        <item>
                            <quantity><cart:quantity/></quantity>
                        </item>
                    </cart:results>
                    <cart:no-results>
                        <message>The item requested could not be found for updating</message>
                    </cart:no-results>
                </cart:items>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:updateE<gt>>

Updates the current cart values:

    <cart:cart>
        <cart:results>
            <cart:update>
                <cart:name>My Updated Cart Name</cart:update>
            <cart:update>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

C<E<lt>cart:idE<gt>> is not valid within an update statement.

=head2 C<E<lt>cart:resultsE<gt>>

Contains the results for the current action. both the singular and plural forms are
valid for your syntactic sanity:

    <cart:cart>
        <cart:result>
            ...
        </cart:result>
    </cart:result>

    <cart:carts>
        <cart:results>

        </cart:results?
    </cart:carts>

=head2 C<E<lt>cart:no-resultsE<gt>>

The anti-results or 'not found' tag. This tag is executed when
C<cart>, C<carts>, C<item>, or C<items> fails to fild a match for it's filters.
As with C<E<lt>cart:resultsE<gt>>, both the
singular and plural forms are available for your enjoyment:

    <cart:cart>
        <cart:no-result>
            ...
        </cart:no-result>
    </cart:result>

    <cart:carts>
        <cart:no-results>

        </cart:no-results?
    </cart:carts>

=head2 C<E<lt>cart:saveE<gt>>

Saves the current cart by setting its type to C<CART_TYPE_SAVED>:

    <cart:cart>
        <cart:results>
            <cart:save/>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:skuE<gt>>

Context aware tag to get or set the sku of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the sku:

    <cart:cart>
        <cart:results>
            <cart:add>
                <cart:sku>sku1234</cart:sku>
            </cart:add>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the sku for the current cart item:

    <cart:cart>
        <cart:results>
            <cart>
                <cart:items>
                        <cart:results>
                            <item>
                                <sku><cart:sku/></sku>
                            </item>
                        </cart:results>
                        <cart:no-results>
                            <message>Your shopping cart is empty</message>
                        </cart:no-results>
                </cart:items>
            </cart>
        <cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:subtotalE<gt>>

Returns the subtotal of the items in the current cart:

    <cart:cart>
        <cart:results>
            <subtotal><cart:subtotal/></subtotal>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:totalE<gt>>

Returns the total of the current cart item:

    <cart:cart>
        <cart:results>
            <cart>
                <cart:items>
                    <cart:results>
                        <item>
                            <total><cart:total/></total>
                        </item>
                    </cart:results>
                    <cart:no-results>
                        <message>Your shopping cart is empty</message>
                    </cart:no-results>
                </cart:items>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 C<E<lt>cart:typeE<gt>>

Context aware tag to get or set the type within various other tags. In C<E<lt>cart:cartE<gt>> or C<E<lt>cart:cartsE<gt>>
it returns the type for the object:

    <cart:cart>
        <cart:results>
            <cart>
                <type><cart:type/></type>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

Within C<E<lt>cart:updateE<gt>> and C<E<lt>cart:newE<gt>>
it sets the type value used in the operation specified:

    <cart:cart>
        <cart:results>
            <cart:update>
                <cart:type>1</cart:type>
            </cart:update>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>
    ...
    <cart:new>
        <cart:type>1</cart:type>
    </cart:new>

=head1 TAG RECIPES

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
