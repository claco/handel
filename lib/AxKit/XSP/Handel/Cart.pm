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

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::Handel::Cart

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:cart="http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Cart"
    >

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

This tag library provides an interface to use C<Handel::Cart> inside of your
AxKit XSP pages.

=head1 TAG HIERARCHY

    <cart:load>
        <cart:filter>
        <cart:cart>
            <cart:add>
                <cart:description></cart:description>
                <cart:id></cart:id>
                <cart:sku></cart:sku>
                <cart:quantity></cart:quantity>
                <cart:price></cart:price>
            </cart:add>
            <cart:clear/>
            <cart:count/>
            <cart:description/>
            <cart:id/>
            <cart:item>
                <cart:filter>
                <cart:description/>
                <cart:id/>
                <cart:sku/>
                <cart:quantity/>
                <cart:update>
                    <cart:description></cart:description>
                    <cart:sku></cart:sku>
                    <cart:quantity></cart:quantity>
                    <cart:price></cart:price>
                </cart:update>
                <cart:price/>
                <cart:total/>
            </cart:item>
            <cart:items>
                <cart:description/>
                <cart:id/>
                <cart:sku/>
                <cart:quantity/>
                <cart:price/>
                <cart:total/>
            </cart:items>
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
        </cart:cart>
        <cart:carts>
            <cart:count/>
            <cart:description/>
            <cart:id/>
            <cart:items>
                <cart:description/>
                <cart:id/>
                <cart:sku/>
                <cart:quantity/>
                <cart:price/>
                <cart:total/>
            </cart:items>
            <cart:name/>
            <cart:subtotal/>
            <cart:type/>
        </cart:carts>
    </cart:load>
    <cart:new>
        <cart:description></cart:description>
        <cart:id></cart:id>
        <cart:name></cart:name>
        <cart:shopper></cart:shopper>
        <cart:type></cart:type>
    </cart:new>

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

Container tag for the current cart inside of the C<E<lt>cart:loadE<gt>> tag.
If C<load> or it's C<filter>s load more than one cart, C<cart> will contain only
the first cart. If you're looking for loop through multiple carts, try
C<E<lt>cart:cartsE<gt>> instead.

    <cart>
        <cart:cart>
            <id><cart:id/></id>
            <name><<cart:name/></name>
            <description><cart:description/></description>
            <subtotal><cart:subtotal/></subtotal>
            <items>
                <cart:items>
                    ...
                </cart:items>
            </items>
        </cart:cart>
    </cart>

=head2 C<E<lt>cart:cartsE<gt>>

Loops through all loaded carts inside of the C<E<lt>cart:loadE<gt>> tag.

    <carts>
        <cart:carts>
            <cart>
                <id><cart:id/></id>
                <name><<cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>
                <items>
                    <cart:items>
                        ...
                    </cart:items>
                </items>
            </cart>
        </cart:carts>
    </carts>

=head2 C<E<lt>cart:clearE<gt>>

Deletes all items in the current shopping cart. This tag is only valid inside of
C<E<lt>cart:cartE<gt>>, not inside of C<E<lt>cart:cartsE<gt>>.

    <cart:carts>
        <cart:clear/>
    </cart:carts>

=head2 C<E<lt>cart:countE<gt>>

Returns the number of items in the current shopping cart. This is valid in both
C<E<lt>cart:cartE<gt>> and C<E<lt>cart:cartsE<gt>>.

    <cart:carts>
        <cart>
            <id><cart:id/></id>
            <name><<cart:name/></name>
            <description><cart:description/></description>
            <subtotal><cart:subtotal/></subtotal>
            <count>cart:count/></count>
        </cart>
    </cart:carts>

=head2 C<E<lt>cart:descriptionE<gt>>

Context aware tag to get or set the description of various other tags. Within
C<E<lt>cart:cartE<gt>> and C<E<lt>cart:cartsE<gt>> it returns the current
carts description:

    <cart:cart>
        <description><cart:description/></description>
    </cart:cart>

Within C<E<lt>cart:addE<gt>> or C<E<lt>cart:updateE<gt>> it sets the current cart
or cart items description:

    <cart:cart>
        <cart:update>
            <cart:description>My Updated Cart Description</cart:description>
        </cart:update>

        <cart:add>
            <cart:description>My New SKU Description</cart:description>
        </cart:add>

        <cart:item sku="1234">
            <cart:update>
                <cart:description>My Updated SKU Description</cart:description>
            <cart:update>
        <cart:item>
    </cart:cart>

=head2 C<E<lt>cart:filterE<gt>>

Adds a new name/value pair to the filter used in C<E<lt>cart:loadE<gt>>,
C<E<lt>cart:deleteE<gt>>, and C<E<lt>cart:itemE<gt>>. Pass the name of the pair in the C<name>
atttribute and the value between the start and end filter tags:

    <cart:load type="0">
        <cart:filter name="shopper">12345678-9098-7654-3212-345678909876</cart:filter>

        <cart:delete>
            <cart:filter name="sku">sku1234</cart:filter>
        <cart:delete>
    </cart:load>


If the same attribute is specified in a filter, the filter takes precedence.

    <cart:load type="0">
        <!-- type == 0 -->
        <cart:filter name="type">1</cart:filter>
        <!-- type == 1 -->
    </cart:load>

You can supply as many C<filter>s as needed.

    <cart:load>
        <cart:filter name="type">0</cart:filter>
        <cart:filter name="shopper">12345678-9098-7654-3212-345678909876</cart:filter>
    </cart:load>

=head2 C<E<lt>cart:idE<gt>>

Context aware tag to get or set the record id within various other tags. In C<E<lt>cart:cartE<gt>>,
C<E<lt>cart:cartsE<gt>>, C<E<lt>cart:itemE<gt>>, and C<E<lt>cart:itemsE<gt>> it returns the
record id for the object:

    <cart:cart>
        <id><cart:id/></id>
        <cart:items>
            <item>
                <id><cart:id/></id>
            </item>
        </cart:items>
    </cart:cart>

Within C<E<lt>cart:deleteE<gt>>, and C<E<lt>cart:newE<gt>>
it sets the id value used in the operation specified:

    <cart:cart>
        <cart:delete>
            <cart:id>11111111-1111-1111-1111-111111111111</cart:id>
        </cart:delete>
    </cart:cart>
    ...
    <cart:new>
        <cart:id>11112222-3333-4444-5555-6666777788889999</cart:id>
        <cart:name>New Cart</cart:name>
    </cart:new>

It cannot be used within C<E<lt>cart:updateE<gt>> and will C<die> if you try updating
the record ids.

=head2 C<E<lt>cart:itemsE<gt>>

Loops through all items in the current cart:

    <cart:cart>
        <items>
            <cart:items>
                <item>
                    <sku><cart:sku/></sku>
                    <description><cart:description/></cart:description>
                    <sku><cart:sku/></sku>
                    <quantity><cart:quantity/></quantity>
                    <price><cart:price/></price>
                    <total><cart:total/></total>
                </item>
            </cart:items>
        </items>
    </cart:cart>

=head2 C<E<lt>cart:loadE<gt>>

Load a specified shopping cart. You can pass filter name/value pairs as attributes
or you can use C<E<lt>cart:filter<gt>> to add them within C<load>:

    <cart:load type="1">
        <cart:filter name="shopper">12345678-9098-7654-3212-345678909876</cart:filter>
    </cart:load>

C<load> must be a top level tag within it's declared namespace. It will C<die> otherwise.

=head2 C<E<lt>cart:nameE<gt>>

Context aware tag to get or set the name within various other tags. In C<E<lt>cart:cartE<gt>>,
 or C<E<lt>cart:cartsE<gt>> it returns the name for the object:

    <cart:cart>
        <name><cart:name/></name>
        ...
    </cart:cart>

Within C<E<lt>cart:updateE<gt>> and C<E<lt>cart:newE<gt>>
it sets the name value used in the operation specified:

    <cart:cart>
        <cart:update>
            <cart:name>My Updated Cart Name</cart:name>
        </cart:update>
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
C<load> must be a top level tag within it's declared namespace. It will C<die> otherwise.

=head2 C<E<lt>cart:priceE<gt>>

Context aware tag to get or set the price of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the price:

    <cart:cart>
        <cart:add>
            <cart:price>1.24</cart:price>
        </cart:add>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> and C<E<lt>cart:itemsE<gt>> it returns the price for the cart item:

    <cart:cart>
        <cart>
            <items>
                <cart:items>
                    <item>
                        <price><cart:price/></price>
                    </item>
                </cart:items>
            </items>
        </cart>
    </cart:cart>

=head2 C<E<lt>cart:quantityE<gt>>

Context aware tag to get or set the quantity of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the quantity:

    <cart:cart>
        <cart:add>
            <cart:quantity>1.24</cart:quantity>
        </cart:add>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> and C<E<lt>cart:itemsE<gt>> it returns the quantity for the cart item:

    <cart:cart>
        <cart>
            <items>
                <cart:items>
                    <item>
                        <quantity><cart:quantity/></quantity>
                    </item>
                </cart:items>
            </items>
        </cart>
    </cart:cart>

=head2 C<E<lt>cart:updateE<gt>>

Updates the current cart values:

    <cart:cart>
        <cart:update>
            <cart:name>My Updated Cart Name</cart:update>
        <cart:update>
    </cart:cart>

C<update> is only valid within C<E<lt>cart:cartE<gt>> and C<E<lt>cart:itemE<gt>>.
C<E<lt>cart:idE<gt>> is not valid withing an update statement.

=head2 C<E<lt>cart:saveE<gt>>

Saves the current cart by setting its type to C<CART_TYPE_SAVED>:

    <cart:cart>
        <cart:save/>
    </cart:cart>

C<save> is only valid in C<E<lt>cart:cartE<gt>>.

=head2 C<E<lt>cart:skuE<gt>>

Context aware tag to get or set the sku of a cart item. In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
it sets the su:

    <cart:cart>
        <cart:add>
            <cart:sku>sku1234</cart:sku>
        </cart:add>
    </cart:cart>

In C<E<lt>cart:itemE<gt>> and C<E<lt>cart:itemsE<gt>> it returns the sku for the cart item:

    <cart:cart>
        <cart>
            <items>
                <cart:items>
                    <item>
                        <sku><cart:sku/></sku>
                    </item>
                </cart:items>
            </items>
        </cart>
    </cart:cart>

=head2 C<E<lt>cart:subtotalE<gt>>

Returns the subtotal of the items in the current cart:

    <cart:cart>
        <subtotal><cart:subtotal/></subtotal>
    </cart:cart>

=head2 C<E<lt>cart:totalE<gt>>

Returns the total of the current cart item:

    <cart:cart>
        <cart>
            <items>
                <cart:items>
                    <item>
                        <total><cart:total/></total>
                    </item>
                </cart:items>
            </items>
        </cart>
    </cart:cart>

=head2 C<E<lt>cart:typeE<gt>>

Context aware tag to get or set the type within various other tags. In C<E<lt>cart:cartE<gt>>,
 or C<E<lt>cart:cartsE<gt>> it returns the type for the object:

    <cart:cart>
        <type><cart:type/></type>
        ...
    </cart:cart>

Within C<E<lt>cart:updateE<gt>> and C<E<lt>cart:newE<gt>>
it sets the type value used in the operation specified:

    <cart:cart>
        <cart:update>
            <cart:type>1</cart:type>
        </cart:update>
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



