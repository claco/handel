# $Id$
package AxKit::XSP::Handel::Cart;
use strict;
use warnings;
use vars qw($NS);
use Handel::ConfigReader;
use Handel::Constants qw(:cart str_to_const);
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

        return unless length($text);

        if ($tag eq 'type' && $text =~ /^[A-Z]{1}/) {
            $text = str_to_const($text);
        };

        if ($tag =~ /^(description|id|name|shopper|type)$/) {
            if ($context[$#context] eq 'new') {
                return ".q|$text|";
            } elsif ($context[$#context] eq 'add') {
                return ".q|$text|";
            } elsif ($context[$#context] eq 'delete') {
                return ".q|$text|";
            } elsif ($context[$#context] eq 'update') {
                return ".q|$text|";
            };
        } elsif ($tag =~ /^(sku|price|quantity)$/) {
            if ($context[$#context] eq 'add') {
                return ".q|$text|";
            } elsif ($context[$#context] eq 'delete') {
                return ".q|$text|";
            } elsif ($context[$#context] eq 'update') {
                return ".q|$text|";
            };
        } elsif ($tag eq 'filter') {
            return ".q|$text|";
        };
        return '';
    };

    sub parse_start {
        my ($e, $tag, %attr) = @_;

        AxKit::Debug(5, "[Handel] parse_start [$tag] context: " . join('->', @context));

        if (exists $attr{'type'}) {
            if ($attr{'type'} =~ /^[A-Z]{1}/) {
                $attr{'type'} = str_to_const($attr{'type'});
            };
        };

        ## cart:uuid
        if ($tag =~ /^(g|u)uid$/) {
            $e->start_expr($tag);
            $e->append_to_script("Handel::Cart->uuid");
            $e->end_expr($tag);

        ## cart:new
        } elsif ($tag eq 'new') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_cart;\nmy \$_xsp_handel_cart_called_new;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_new_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_new_filter;' ;

            return "\n{\n$code\n";


        ## cart:restore
        } elsif ($tag eq 'restore') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] =~ /^(cart(s?))$/);

            push @context, $tag;

            my $mode = str_to_const($attr{'mode'}) || CART_MODE_APPEND;
            delete $attr{'mode'};

            my $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_restore_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_restore_filter;' ;

            return "\n{\nmy \$_xsp_handel_cart_restore_mode = $mode;\n$code\n";

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


        ## cart:carts
        } elsif ($tag eq 'carts') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \@_xsp_handel_cart_carts;\nmy \$_xsp_handel_carts_called_load;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_carts_load_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_carts_load_filter;' ;

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

           return "\n\$_xsp_handel_cart_cart->clear;\n";


        ## cart:add
        } elsif ($tag eq 'add') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(new|cart(s?))$/);

            push @context, $tag;

            my $code = "my \$_xsp_handel_cart_item;\nmy \$_xsp_handel_cart_called_add;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_cart_add_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_cart_add_filter;' ;

            return "\n{\n$code\n";


        ## cart:update
        } elsif ($tag eq 'update') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^((cart(s?)|item(s?)))$/);

            push @context, $tag;

            if ($context[$#context-2] =~ /^(cart(s?))$/) {
                return "\n\$_xsp_handel_cart_cart->autoupdate(0);\n";
            } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                return "\n\$_xsp_handel_cart_item->autoupdate(0);\n";
            };

            return '';


        } elsif ($tag eq 'save') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context-1] !~ /^(cart(s?))$/);

            return '
                $_xsp_handel_cart_cart->save;
                $_xsp_handel_cart_cart->update;
            ';

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
                return "\n\$_xsp_handel_cart_new_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'add' && $tag =~ /^(id|description)$/) {
                return "\n\$_xsp_handel_cart_add_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] =~ /^(new|cart(s?))$/) {
                $e->start_expr($tag);

                if ($tag eq 'subtotal' && ($attr{'format'} || $attr{'convert'})) {
                    my $cfg = Handel::ConfigReader->new();
                    my $code   = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};
                    my $format = $attr{'options'} || $cfg->{'HandelCurrencyFormat'};
                    my $from   = $attr{'from'}    || $cfg->{'HandelCurrencyCode'};
                    my $to     = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};

                    AxKit::Debug(5, "[Handel] [$tag] code=$code, format=$format, from=$from, to=$to");

                    if ($attr{'convert'}) {
                        $e->append_to_script("\$_xsp_handel_cart_cart->$tag->convert('$from', '$to', '".$attr{'format'}."', '$format');\n");
                    } elsif ($attr{'format'}) {
                        $e->append_to_script("\$_xsp_handel_cart_cart->$tag->format('$code', '$format');\n");
                    };
                } else {
                    $e->append_to_script("\$_xsp_handel_cart_cart->$tag;\n");
                };
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
                return "\n\$_xsp_handel_cart_delete_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'update') {
                throw Handel::Exception::Taglib(
                    -text => translate("Tag '[_1]' not valid here", $tag)
                ) if ($tag eq 'id');

                if ($context[$#context-2] =~ /^(cart(s?))$/) {
                    return "\n\$_xsp_handel_cart_cart->$tag(''";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return "\n\$_xsp_handel_cart_item->$tag(''";
                };
            };


        ## cart item property tags
        ## cart:sku, price, quantity, total
        } elsif ($tag =~ /^(sku|price|quantity|total)$/) {
            if ($context[$#context] eq 'add' && $tag ne 'total') {
                return "\n\$_xsp_handel_cart_add_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] =~ /^item(s?)$/) {
                $e->start_expr($tag);

                if ($tag =~ /^(price|total)$/ && ($attr{'format'} || $attr{'convert'})) {
                    my $cfg = Handel::ConfigReader->new();
                    my $code   = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};
                    my $format = $attr{'options'} || $cfg->{'HandelCurrencyFormat'};
                    my $from   = $attr{'from'}    || $cfg->{'HandelCurrencyCode'};
                    my $to     = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};

                    AxKit::Debug(5, "[Handel] [$tag] code=$code, format=$format, from=$from, to=$to");

                    if ($attr{'convert'}) {
                        $e->append_to_script("\$_xsp_handel_cart_item->$tag->convert('$from', '$to', '".$attr{'format'}."', '$format');\n");
                    } elsif ($attr{'format'}) {
                        $e->append_to_script("\$_xsp_handel_cart_item->$tag->format('$code', '$format');\n");
                    };
                } else {
                    $e->append_to_script("\$_xsp_handel_cart_item->$tag;\n");
                };
            } elsif ($context[$#context] eq 'delete') {
                return "\n\$_xsp_handel_cart_delete_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(cart(s?))$/) {
                    return "\n\$_xsp_handel_cart_cart->$tag(''";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return "\n\$_xsp_handel_cart_item->$tag(''";
                };
            };


        ## cart:filter
        } elsif ($tag eq 'filter') {
            my $key = $attr{'name'} || 'id';

            if ($context[$#context] eq 'cart') {
                return "\n\$_xsp_handel_cart_load_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'carts') {
                return "\n\$_xsp_handel_carts_load_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'item') {
                return "\n\$_xsp_handel_cart_item_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'items') {
                return "\n\$_xsp_handel_cart_items_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'restore') {
                return "\n\$_xsp_handel_cart_restore_filter{'$key'} = ''";
            };


        ## cart:results
        } elsif ($tag =~ /^result(s?)$/) {
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
            } elsif ($context[$#context-1] eq 'carts') {
                return '
                    if (!$_xsp_handel_carts_called_load) {
                        @_xsp_handel_cart_carts = (scalar keys %_xsp_handel_carts_load_filter) ?
                            Handel::Cart->load(\%_xsp_handel_carts_load_filter) :
                            Handel::Cart->load();
                            $_xsp_handel_carts_called_load = 1;
                    };
                    foreach my $_xsp_handel_cart_cart (@_xsp_handel_cart_carts) {

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
        } elsif ($tag =~ /^no-result(s?)$/) {
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
            } elsif ($context[$#context-1] eq 'carts') {
                return '
                    if (!$_xsp_handel_carts_called_load) {
                        @_xsp_handel_cart_carts = (scalar keys %_xsp_handel_carts_load_filter) ?
                            Handel::Cart->load(\%_xsp_handel_carts_load_filter) :
                            Handel::Cart->load();
                            $_xsp_handel_carts_called_load = 1;
                    };
                    if (!scalar @_xsp_handel_cart_carts) {
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

        AxKit::Debug(5, "[Handel] parse_end   [$tag] context: " . join('->', @context));

        ## cart:new
        if ($tag eq 'new') {
            pop @context;

            return '
                if (!$_xsp_handel_cart_called_new && scalar keys %_xsp_handel_cart_new_filter) {
                    $_xsp_handel_cart_cart = Handel::Cart->new(\%_xsp_handel_cart_new_filter);
                    $_xsp_handel_cart_called_new = 1;
                };
            };';


        ## cart:restore
        } elsif ($tag eq 'restore') {
            pop @context;

            return '
                $_xsp_handel_cart_cart->restore(\%_xsp_handel_cart_restore_filter,
                    $_xsp_handel_cart_restore_mode);
            };
            ';


        ## cart:cart
        } elsif ($tag eq 'cart') {
            pop @context;

            return "\n};\n";


        ## cart:carts
        } elsif ($tag eq 'carts') {
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


        ## cart:update
        } elsif ($tag eq 'update') {
            if ($context[$#context-2] =~ /^(cart(s?))$/) {
                pop @context;
                return '
                    $_xsp_handel_cart_cart->update;
                ';
            } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                pop @context;
                return '
                    $_xsp_handel_cart_item->update;
                ';
            };

            pop @context;


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
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(cart(s?))$/) {
                    return ");\n";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return ");\n";
                };
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
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(cart(s?))$/) {
                    return ");\n";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return ");\n";
                };
            };


        ## cart:filter
        } elsif ($tag eq 'filter') {
            if ($context[$#context] eq 'cart') {
                return ";\n";
            } elsif ($context[$#context] eq 'carts') {
                return ";\n";
            } elsif ($context[$#context] eq 'item') {
                return ";\n";
            } elsif ($context[$#context] eq 'items') {
                return ";\n";
            } elsif ($context[$#context] eq 'restore') {
                return ";\n";
            };


        ## cart:results
        } elsif ($tag =~ /^result(s?)$/) {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'cart') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'carts') {
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
        } elsif ($tag =~ /^no-result(s?)$/) {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'cart') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'carts') {
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

AxKit::XSP::Handel::Cart - AxKit XSP Shopping Cart Taglib

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

This tag library provides an interface to use C<Handel::Cart> inside of your
AxKit XSP pages.

=head1 CHANGES

Starting in version C<0.09>, C<E<lt>cart:typeE<gt>>, the C<type> attribute,
and the C<mode> attribute in C<E<lt>cart:restoreE<gt>> now take the constants
declared in C<Handel::Constants>:

    <cart:type>CART_TYPE_SAVED</cart:type>

    <cart:new type="CART_TYPE_SAVED">
        ...
    </cart:new>

    <cart:restore mode="CART_MODE_APPEND">
        ...
    </cart:restore>

Starting in version C<0.13>, the currency formatting options from
C<Handel::Currency> are now available within the taglib:

     <cart:price format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

Starting in version C<0.15>, the currency conversion options from
C<Handel::Currency> are now available within the taglib:

    <cart:subtotal convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />

=head1 TAG HIERARCHY

    <cart:uuid/>
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
            <cart:subtotal
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
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
                    <cart:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
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
                    <cart:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
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
                    <cart:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <cart:quantity/>
                    <cart:sku/>
                    <cart:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
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
            <cart:restore mode="CART_MODE_APPEND|CART_MODE_MERGE|CART_MODE_REPLACE" description|id|name|shopper|type="value"...>
                <cart:filter name="description|id|name|shopper|type">value</cart:filter>
            </cart:restore>
            <cart:save/>
            <cart:subtotal
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
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

=head2 <cart:add>

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

This tag is only valid within the C<E<lt>cart:resultsE<gt>> block for C<cart>
and C<carts>. See C<Handel::Cart> for more information about adding parts to
the shopping cart.

You can also access the newly added item using the C<E<lt>cart:resultsE<gt>>.

=head2 <cart:cart>

Container tag for the current cart used to load a specific cart.

If C<cart> or its C<filter>s load more than one cart, C<cart> will contain only
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

=head2 <cart:carts>

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

=head2 <cart:clear>

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

=head2 <cart:count>

Returns the number of items in the current shopping cart.

    <cart:cart>
        <cart:results>
            <cart>
                <id><cart:id/></id>
                <name><<cart:name/></name>
                <description><cart:description/></description>
                <subtotal><cart:subtotal/></subtotal>
                <count><cart:count/></count>
            </cart>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 <cart:description>

Context aware tag to get or set the description of various other parent tags.
Within C<E<lt>cart:cartE<gt>> or C<E<lt>cart:cartsE<gt>> it returns the current
carts description:

    <cart:cart>
        <cart:results>
            <description><cart:description/></description>
        </cart:results>
    </cart:cart>

Within C<E<lt>cart:addE<gt>> or C<E<lt>cart:updateE<gt>> it sets the current
cart or cart items description:

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

=head2 <cart:filter>

Adds a new name/value pair to the filter used in C<E<lt>cart:cartE<gt>>,
C<E<lt>cart:cartsE<gt>>, C<E<lt>cart:deleteE<gt>>, C<E<lt>cart:itemE<gt>>,
and C<E<lt>cart:itemsE<gt>>. Pass the name of the pair in the C<name>
attribute and the value between the start and end filter tags:

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

If the same attribute is specified in a filter, the child filter tag value
takes precedence over the parent tags attribute.

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

=head2 <cart:id>

Context aware tag to get or set the record id within various other tags.
In C<E<lt>cart:cartE<gt>> and C<E<lt>cart:itemE<gt>> it returns the
record id for the object:

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

Within C<E<lt>cart:addE<gt>>, C<E<lt>cart:deleteE<gt>>, and
C<E<lt>cart:newE<gt>> it sets the id value used in the operation specified:

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

It cannot be used within C<E<lt>cart:updateE<gt>> and will return a
C<Handel::Exception::Taglib> exception if you try updating
the record ids which are the primary keys.

=head2 <cart:items>

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

=head2 <cart:name>

Context aware tag to get or set the name within various other tags.
In C<E<lt>cart:cartE<gt>> it returns the name for the cart object:

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

=head2 <cart:new>

Creates a new shopping cart using the supplied attributes and child tags:

    <cart:new type="1">
        <cart:id>22222222-2222-2222-2222-222222222222</cart:id>
        <cart:shopper><request:shopper/></cart:shopper>
        <cart:name>New Cart</cart:name>
    </cart:new>

The child tags take precedence over the attributes of the same name.
C<new> B<must be a top level tag> within it's declared namespace.
It will throw an C<Handel::Exception::Taglib> exception otherwise.

=head2 <cart:price>

Context aware tag to get or set the price of a cart item.
In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>>
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

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the price
for the cart item:

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

=head3 Currency Formatting

Starting in version C<0.13>, the currency formatting options from
C<Handel::Currency> are now available within the taglib if
C<Locale::Currency::Format> is installed.

     <cart:price format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

=over

=item format

Toggle switch that enables or disables currency formatting. If empty,
unspecified, or set to 0, no formatting will take place and the result price
(usually in decimal form) is returned unaltered.

If C<format> is set to anything else, the default formatting will be applied.
See C<Handel::Currency> for the default currency formatting settings.

=item code

If formatting is enabled, the C<code> attribute specifies the desired three
letter ISO currency code to be used when formatting currency.
See C<Locale::Currency::Format> for the available codes.

If you are also using the currency conversion options below, the value of
C<to> will always be used first, even if C<code> is not empty.
If C<to> is empty and C<code> is also empty, the C<HandelCurrencyCode>
configuration setting will be used instead.

=item options

If formatting is enabled, the C<options> attribute specifies the desired
formatting options to be used when formatting currency.
See C<Locale::Currency::Format> for the available options.

=back

=head3 Currency Conversion

Starting in version C<0.15>, the currency conversion options from
C<Handel::Currency> are now available within the taglib if
C<Finance::Currency::Convert::WebserviceX> is installed.

    <cart:price convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />

=over

=item convert

Toggle switch that enables or disables currency conversion. If empty,
unspecified, or set to 0, no currency conversion will take place and the
result price is returned unaltered.

If C<convert> is set to anything else, the default conversion will be
applied. See C<Handel::Currency> for the default currency conversion settings.

=item from

If conversion is enabled, the C<from> attribute specifies the three letter
ISO currency code of the price to be converted. If no C<from> is specified,
the C<HandelCurrencyCode> configuration setting will be used instead.
See C<Locale::Currency> for the available codes.

=item to

If conversion is enabled, the C<to> attribute specifies what the current
C<price> should be converted to. If no C<to> is specified, the C<code>
attribute from the formatting options above will be used instead.
If both C<to> and C<code> are empty, the C<HandelCurrencyCode>
configuration setting will be used as a last resort.

=back

If you try to convert from and to the same currency, the C<price> is returned
as is.

=head3 Precedence

If you are using both the currency conversion and the currency formatting
options, the conversion will be performaed first, then the result will
be formatted.

=head2 <cart:quantity>

Context aware tag to get or set the quantity of a cart item.
In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>> it sets the quantity:

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

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the quantity
for the cart item:

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

=head2 <cart:update>

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

=head2 <cart:results>

Contains the results for the current action. both the singular and plural
forms are valid for your syntactic sanity:

    <cart:cart>
        <cart:result>
            ...
        </cart:result>
    </cart:result>

    <cart:carts>
        <cart:results>

        </cart:results?
    </cart:carts>

=head2 <cart:no-results>

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

=head2 <cart:restore>

Restores another cart into the current cart.

    <cart:restore mode="CART_MODE_APPEND">
        <cart:filter name="id">11111111-1111-1111-1111-111111111111</cart:filter>
    </cart:restore>

See L<Handel::Constants> for the available C<mode> values.

=head2 <cart:save>

Saves the current cart by setting its type to C<CART_TYPE_SAVED>:

    <cart:cart>
        <cart:results>
            <cart:save/>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

=head2 <cart:sku>

Context aware tag to get or set the sku of a cart item.
In C<E<lt>cart:addE<gt>> and C<E<lt>cart:updateE<gt>> it sets the sku:

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

In C<E<lt>cart:itemE<gt>> or C<E<lt>cart:itemsE<gt>> it returns the sku
for the current cart item:

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

=head2 <cart:subtotal>

Returns the subtotal of the items in the current cart:

    <cart:cart>
        <cart:results>
            <subtotal><cart:subtotal/></subtotal>
        </cart:results>
        <cart:no-results>
            <message>The cart requested could not be found.</message>
        </cart:no-results>
    </cart:cart>

Starting in version C<0.13>, the currency formatting options from
C<Handel::Currency> are now available within the taglib.

     <cart:subtotal format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

Starting in version C<0.15>, the currency conversion options from
C<Handel::Currency> are now available within the taglib.

    <cart:subtotal convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />

See <cart:price> above for further details about price formatting.

=head2 <cart:total>

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

Starting in version C<0.13>, the currency formatting options from
C<Handel::Currency> are now available within the taglib.

     <cart:total format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

Starting in version C<0.15>, the currency conversion options from
C<Handel::Currency> are now available within the taglib.

    <cart:total convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />


See <cart:price> above for further details about price formatting.

=head2 <cart:type>

Context aware tag to get or set the type within various other tags.
In C<E<lt>cart:cartE<gt>> or C<E<lt>cart:cartsE<gt>> it returns the
type for the object:

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

=head2 <cart:uuid/>

This tag returns a new uuid/guid for use in C<new> and C<add> in the
following format:

    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

For those like me who always type the wrong thing, C<E<lt>cart:guid/<gt>>
returns the same things as C<E<lt>cart:uuid/<gt>>.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
