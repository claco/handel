# $Id$
package AxKit::XSP::Handel::Order;
use strict;
use warnings;
use vars qw($NS);
use Handel::ConfigReader;
use Handel::Constants qw(:order str_to_const);
use Handel::Exception;
use Handel::L10N qw(translate);
use base 'Apache::AxKit::Language::XSP';

$NS  = 'http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Order';

{
    my @context = 'root';

    sub start_document {
        return "use Handel::Order;\n";
    };

    sub parse_char {
        my ($e, $text) = @_;
        my $tag = $e->current_element();

        return unless length($text);

        if ($tag eq 'type' && $text =~ /^[A-Z]{1}/) {
            $text = str_to_const($text);
        };

        if ($tag =~ /^(description|id|name|shopper|type|
        billtofirstname|billtolastname|billtoaddress1|billtoaddress2|billtoaddress3|
        billtocity|billtostate|billtozip|billtocountry|
        billtodayphone|billtonightphone|billtofax|billtoemail|
        comments|created|handling|number|shipmethod|shipping|shiptosameasbillto|
        shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|shiptoaddress3|
        shiptocity|shiptostate|shiptozip|shiptocountry|
        shiptodayphone|shiptonightphone|shiptofax|shiptoemail|
        subtotal|total||updated)$/x) {
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

        AxKit::Debug(5, "[Handel] [Order] parse_start [$tag] context: " . join('->', @context));

        if (exists $attr{'type'}) {
            if ($attr{'type'} =~ /^[A-Z]{1}/) {
                $attr{'type'} = str_to_const($attr{'type'});
            };
        };

        ## order:uuid
        if ($tag =~ /^(g|u)uid$/) {
            $e->start_expr($tag);
            $e->append_to_script("Handel::Order->uuid");
            $e->end_expr($tag);

        ## order:new
        } elsif ($tag eq 'new') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $noprocess = $attr{'noprocess'} || 0;
            delete $attr{'noprocess'};

            my $code = "my \$_xsp_handel_order_new_noprocess = $noprocess;my \$_xsp_handel_order_order;\nmy \$_xsp_handel_order_called_new;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_order_new_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_new_filter;' ;

            return "\n{\n$code\n";


        ## order:cart
        } elsif ($tag eq 'cart') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'new');

            push @context, $tag;

            my $code = "my \%_xsp_handel_order_new_cart_filter;\n";
            if (scalar keys %attr) {
                $code .=  '%_xsp_handel_order_new_cart_filter = ("' . join('", "', %attr) . '");' . "\n";
            };

            return $code;

        ## order:order
        } elsif ($tag eq 'order') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \$_xsp_handel_order_order;\nmy \$_xsp_handel_order_called_load;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_order_load_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_load_filter;' ;

            return "\n{\n$code\n";


        ## order:orders
        } elsif ($tag eq 'order') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of other Handel tags", $tag)
            ) if ($context[$#context] ne 'root');

            push @context, $tag;

            my $code = "my \@_xsp_handel_order_orders;\nmy \$_xsp_handel_orders_called_load;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_orders_load_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_orders_load_filter;' ;

            return "\n{\n$code\n";


        ## order:item
        } elsif ($tag eq 'item') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] =~ /^(order(s?))$/);

            push @context, $tag;

            my $code = "my \$_xsp_handel_order_item;\nmy \$_xsp_handel_order_called_item;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_order_item_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_item_filter;' ;

            return "\n{\n$code\n";


        ## order:items
        } elsif ($tag eq 'items') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid inside of tag '" . $context[$#context] . "'", $tag)
            ) if ($context[$#context] =~ /^(order(s?))$/);

            push @context, $tag;

            my $code = "my \@_xsp_handel_order_items;\nmy \$_xsp_handel_order_called_items;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_order_items_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_items_filter;' ;

            return "\n{\n$code\n";


        ## order:clear
        } elsif ($tag eq 'clear') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(order(s?))$/);

           return "\n\$_xsp_handel_order_order->clear;\n";


        ## order:add
        } elsif ($tag eq 'add') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(new|order(s?))$/);

            push @context, $tag;

            my $code = "my \$_xsp_handel_order_item;\nmy \$_xsp_handel_order_called_add;\n";
            $code .= scalar keys %attr ?
                'my %_xsp_handel_order_add_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_add_filter;' ;

            return "\n{\n$code\n";


        ## order:update
        } elsif ($tag eq 'update') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^((order(s?)|item(s?)))$/);

            push @context, $tag;

            if ($context[$#context-2] =~ /^(order(s?))$/) {
                return "\n\$_xsp_handel_order_order->autoupdate(0);\n";
            } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                return "\n\$_xsp_handel_order_item->autoupdate(0);\n";
            };

            return '';


        } elsif ($tag eq 'save') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context-1] !~ /^(order(s?))$/);

            return '
                $_xsp_handel_order_order->save;
                $_xsp_handel_order_order->update;
            ';

        ## order:delete
        } elsif ($tag eq 'delete') {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] ne 'results' || $context[$#context-1] !~ /^(order(s?))$/);

            push @context, $tag;

            my $code .= scalar keys %attr ?
                'my %_xsp_handel_order_delete_filter = ("' . join('", "', %attr) . '");' :
                'my %_xsp_handel_order_delete_filter;' ;

            return "\n{\n$code\n";


        ## order property tags
        ## order:description, id, name, shopper, type, count, subtotal
        ## billtofirstname
        } elsif ($tag =~ /^(description|id|name|shopper|type|count|subtotal|
        billtofirstname|billtolastname|billtoaddress1|billtoaddress2|billtoaddress3|
        billtocity|billtostate|billtozip|billtocountry|
        billtodayphone|billtonightphone|billtofax|billtoemail|
        comments|created|handling|number|shipmethod|shipping|shiptosameasbillto|
        shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|shiptoaddress3|
        shiptocity|shiptostate|shiptozip|shiptocountry|
        shiptodayphone|shiptonightphone|shiptofax|shiptoemail|
        subtotal|updated)$/x) {
            if ($context[$#context] eq 'new' && $tag !~ /^(count)$/) {
                return "\n\$_xsp_handel_order_new_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'add' && $tag =~ /^(id|description)$/) {
                return "\n\$_xsp_handel_order_add_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] =~ /^(new|order(s?))$/) {
                $e->start_expr($tag);

                if ($tag eq 'subtotal' && ($attr{'format'} || $attr{'convert'})) {
                    my $cfg = Handel::ConfigReader->new();
                    my $code   = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};
                    my $format = $attr{'options'} || $cfg->{'HandelCurrencyFormat'};
                    my $from   = $attr{'from'}    || $cfg->{'HandelCurrencyCode'};
                    my $to     = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};

                    AxKit::Debug(5, "[Handel] [Order] [$tag] code=$code, format=$format, from=$from, to=$to");

                    if ($attr{'convert'}) {
                        $e->append_to_script("\$_xsp_handel_order_order->$tag->convert('$from', '$to', '".($attr{'format'}||'')."', '$format');\n");
                    } elsif ($attr{'format'}) {
                        $e->append_to_script("\$_xsp_handel_order_order->$tag->format('$code', '$format');\n");
                    };
                } else {
                    $e->append_to_script("\$_xsp_handel_order_order->$tag;\n");
                };
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'item') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_order_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'items') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_order_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_order_item->$tag;\n");
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return "\n\$_xsp_handel_order_delete_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'update') {
                throw Handel::Exception::Taglib(
                    -text => translate("Tag '[_1]' not valid here", $tag)
                ) if ($tag eq 'id');

                if ($context[$#context-2] =~ /^(order(s?))$/) {
                    return "\n\$_xsp_handel_order_order->$tag(''";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return "\n\$_xsp_handel_order_item->$tag(''";
                };
            };


        ## order item property tags
        ## order:sku, price, quantity, total
        } elsif ($tag =~ /^(sku|price|quantity|total)$/) {
            if ($context[$#context] eq 'new') {
                return "\n\$_xsp_handel_order_new_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'add') {
                return "\n\$_xsp_handel_order_add_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->start_expr($tag);
                $e->append_to_script("\$_xsp_handel_order_item->$tag;\n");
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] =~ /^(new|order(s?)|item(s?))$/) {
                $e->start_expr($tag);

                if ($tag =~ /^(price|total)$/ && ($attr{'format'} || $attr{'convert'})) {
                    my $cfg = Handel::ConfigReader->new();
                    my $code   = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};
                    my $format = $attr{'options'} || $cfg->{'HandelCurrencyFormat'};
                    my $from   = $attr{'from'}    || $cfg->{'HandelCurrencyCode'};
                    my $to     = $attr{'to'}      || $attr{'code'} || $cfg->{'HandelCurrencyCode'};

                    AxKit::Debug(5, "[Handel] [Order] [$tag] code=$code, format=$format, from=$from, to=$to");

                    if ($attr{'convert'}) {
                        if ($context[$#context-1] =~ /^(new|order(s?))$/) {
                            $e->append_to_script("\$_xsp_handel_order_order->$tag->convert('$from', '$to', '".($attr{'format'}||'')."', '$format');\n");
                        } else {
                            $e->append_to_script("\$_xsp_handel_order_item->$tag->convert('$from', '$to', '".($attr{'format'}||'')."', '$format');\n");
                        };
                    } elsif ($attr{'format'}) {
                        if ($context[$#context-1] =~ /^(new|order(s?))$/) {
                            $e->append_to_script("\$_xsp_handel_order_order->$tag->format('$code', '$format');\n");
                        } else {
                            $e->append_to_script("\$_xsp_handel_order_item->$tag->format('$code', '$format');\n");
                        };
                    };
                } else {
                    if ($context[$#context-1] =~ /^(new|order(s?))$/) {
                        $e->append_to_script("\$_xsp_handel_order_order->$tag;\n");
                    } else {
                        $e->append_to_script("\$_xsp_handel_order_item->$tag;\n");
                    };
                };
            } elsif ($context[$#context] eq 'delete') {
                return "\n\$_xsp_handel_order_delete_filter{$tag} = ''";
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(order(s?))$/) {
                    return "\n\$_xsp_handel_order_order->$tag(''";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return "\n\$_xsp_handel_order_item->$tag(''";
                };
            };


        ## order:filter
        } elsif ($tag eq 'filter') {
            my $key = $attr{'name'} || 'id';

            if ($context[$#context] eq 'order') {
                return "\n\$_xsp_handel_order_load_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'orders') {
                return "\n\$_xsp_handel_orders_load_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'item') {
                return "\n\$_xsp_handel_order_item_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'items') {
                return "\n\$_xsp_handel_order_items_filter{'$key'} = ''";
            } elsif ($context[$#context] eq 'cart') {
                return "\n\$_xsp_handel_order_new_cart_filter{'$key'} = ''";
            };


        ## order:results
        } elsif ($tag =~ /^result(s?)$/) {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] !~ /^(new|add|order(s?)|item(s?))$/);

            push @context, $tag;

            if ($context[$#context-1] eq 'new') {
                return '
                    if (!$_xsp_handel_order_called_new && scalar keys %_xsp_handel_order_new_filter) {
                        $_xsp_handel_order_order = Handel::Order->new(\%_xsp_handel_order_new_filter, $_xsp_handel_order_new_noprocess);
                        $_xsp_handel_order_called_new = 1;
                    };
                    if ($_xsp_handel_order_order) {

                ';
            } elsif ($context[$#context-1] eq 'order') {
                return '
                    if (!$_xsp_handel_order_called_load) {
                        $_xsp_handel_order_order = (scalar keys %_xsp_handel_order_load_filter) ?
                            Handel::Order->load(\%_xsp_handel_order_load_filter, 1)->next :
                            Handel::Order->load(undef, 1)->next;
                            $_xsp_handel_order_called_load = 1;
                    };
                    if ($_xsp_handel_order_order) {

                ';
            } elsif ($context[$#context-1] eq 'orders') {
                return '
                    if (!$_xsp_handel_orders_called_load) {
                        @_xsp_handel_order_orders = (scalar keys %_xsp_handel_orders_load_filter) ?
                            Handel::Order->load(\%_xsp_handel_orders_load_filter) :
                            Handel::Order->load();
                            $_xsp_handel_orders_called_load = 1;
                    };
                    foreach my $_xsp_handel_order_order (@_xsp_handel_order_orders) {

                ';
            } elsif ($context[$#context-1] eq 'item') {
                return '
                    if (!$_xsp_handel_order_called_item) {
                        $_xsp_handel_order_item = (scalar keys %_xsp_handel_order_item_filter) ?
                            $_xsp_handel_order_order->items(\%_xsp_handel_order_item_filter, 1)->next :
                            $_xsp_handel_order_order->items(undef, 1)->next;
                            $_xsp_handel_order_called_item = 1;
                    };
                    if ($_xsp_handel_order_item) {

                ';
            } elsif ($context[$#context-1] eq 'items') {
                return '
                    if (!$_xsp_handel_order_called_items) {
                        @_xsp_handel_order_items = (scalar keys %_xsp_handel_order_items_filter) ?
                            $_xsp_handel_order_order->items(\%_xsp_handel_order_items_filter) :
                            $_xsp_handel_order_order->items();
                            $_xsp_handel_order_called_items = 1;
                    };
                    foreach my $_xsp_handel_order_item (@_xsp_handel_order_items) {

                ';
            } elsif ($context[$#context-1] eq 'add') {
                return '
                    if (!$_xsp_handel_order_called_add && scalar keys %_xsp_handel_order_add_filter) {
                        $_xsp_handel_order_item = $_xsp_handel_order_order->add(\%_xsp_handel_order_add_filter);
                        $_xsp_handel_order_called_add = 1;
                    };
                    if ($_xsp_handel_order_item) {

                ';
            };


        ## order:no-results
        } elsif ($tag =~ /^no-result(s?)$/) {
            throw Handel::Exception::Taglib(
                -text => translate("Tag '[_1]' not valid here", $tag)
            ) if ($context[$#context] !~ /^(new|add|order(s?)|item(s?))$/);

            push @context, $tag;

            if ($context[$#context-1] eq 'new') {
                return '
                    if (!$_xsp_handel_order_called_new && scalar keys %_xsp_handel_order_new_filter) {
                        $_xsp_handel_order_order = Handel::Order->new(\%_xsp_handel_order_new_filter, $_xsp_handel_order_new_noprocess);
                        $_xsp_handel_order_called_new = 1;
                    };
                    if (!$_xsp_handel_order_order) {
                ';
            } elsif ($context[$#context-1] eq 'order') {
                return '
                    if (!$_xsp_handel_order_called_load) {
                        $_xsp_handel_order_order = (scalar keys %_xsp_handel_order_load_filter) ?
                            Handel::Order->load(\%_xsp_handel_order_load_filter, 1)->next :
                            Handel::Order->load(undef, 1)->next;
                            $_xsp_handel_order_called_load = 1;
                    };
                    if (!$_xsp_handel_order_order) {
                ';
            } elsif ($context[$#context-1] eq 'order') {
                return '
                    if (!$_xsp_handel_orders_called_load) {
                        @_xsp_handel_order_orders = (scalar keys %_xsp_handel_orders_load_filter) ?
                            Handel::Order->load(\%_xsp_handel_orders_load_filter) :
                            Handel::Order->load();
                            $_xsp_handel_orders_called_load = 1;
                    };
                    if (!scalar @_xsp_handel_order_orders) {
                ';
            } elsif ($context[$#context-1] eq 'item') {
                return '
                    if (!$_xsp_handel_order_called_item) {
                        $_xsp_handel_order_item = (scalar keys %_xsp_handel_order_item_filter) ?
                            $_xsp_handel_order_order->items(\%_xsp_handel_order_item_filter, 1)->next :
                            $_xsp_handel_order_order->items(undef, 1)->next;
                            $_xsp_handel_order_called_item = 1;
                    };
                    if (!$_xsp_handel_order_item) {
                ';
            } elsif ($context[$#context-1] eq 'items') {
                return '
                    if (!$_xsp_handel_order_called_items) {
                        @_xsp_handel_order_items = (scalar keys %_xsp_handel_order_items_filter) ?
                            $_xsp_handel_order_order->items(\%_xsp_handel_order_items_filter) :
                            $_xsp_handel_order_order->items();
                            $_xsp_handel_order_called_items = 1;
                    };
                    if (!scalar @_xsp_handel_order_items) {
                ';
            } elsif ($context[$#context-1] eq 'add') {
                return '
                    if (!$_xsp_handel_order_called_add && scalar keys %_xsp_handel_order_add_filter) {
                        $_xsp_handel_order_item = $_xsp_handel_order_order->add(\%_xsp_handel_order_add_filter);
                        $_xsp_handel_order_called_add = 1;
                    };
                    if (!$_xsp_handel_order_item) {
                ';
            };
        };

        return '';
    };

    sub parse_end {
        my ($e, $tag) = @_;

        AxKit::Debug(5, "[Handel] [Order] parse_end   [$tag] context: " . join('->', @context));

        ## order:new
        if ($tag eq 'new') {
            pop @context;

            return '
                if (!$_xsp_handel_order_called_new && scalar keys %_xsp_handel_order_new_filter) {
                    $_xsp_handel_order_order = Handel::Order->new(\%_xsp_handel_order_new_filter);
                    $_xsp_handel_order_called_new = 1;
                };
            };';


        ## order:cart
        } elsif ($tag eq 'cart') {
            pop @context;

            return  '
                if (scalar keys %_xsp_handel_order_new_cart_filter) {
                    $_xsp_handel_order_new_filter{\'cart\'} = \%_xsp_handel_order_new_cart_filter;
                };
            ';


        ## order:order
        } elsif ($tag eq 'order') {
            pop @context;

            return "\n};\n";


        ## order:orders
        } elsif ($tag eq 'order') {
            pop @context;

            return "\n};\n";


        ## order:item
        } elsif ($tag eq 'item') {
            pop @context;

            return "\n};\n";


        ## order:items
        } elsif ($tag eq 'items') {
            pop @context;

            return "\n};\n";


        ## order:add
        } elsif ($tag eq 'add') {
            pop @context;

            return '
                if (!$_xsp_handel_order_called_add && scalar keys %_xsp_handel_order_add_filter) {
                    $_xsp_handel_order_item = $_xsp_handel_order_order->add(\%_xsp_handel_order_add_filter);
                    $_xsp_handel_order_called_add = 1;
                };
            };
            ';


        ## order:update
        } elsif ($tag eq 'update') {
            if ($context[$#context-2] =~ /^(order(s?))$/) {
                pop @context;
                return '
                    $_xsp_handel_order_order->update;
                ';
            } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                pop @context;
                return '
                    $_xsp_handel_order_item->update;
                ';
            };

            pop @context;


        ## order:delete
        } elsif ($tag eq 'delete') {
            pop @context;

            return '
                if (scalar keys %_xsp_handel_order_delete_filter) {
                    $_xsp_handel_order_order->delete(\%_xsp_handel_order_delete_filter);
                };
            };
            ';

        ## order propery tags
        ## order:description, id, name, shopper, type, count, subtotal
        } elsif ($tag =~ /^(description|id|name|shopper|type|count|subtotal|
        billtofirstname|billtolastname|billtoaddress1|billtoaddress2|billtoaddress3|
        billtocity|billtostate|billtozip|billtocountry|
        billtodayphone|billtonightphone|billtofax|billtoemail|
        comments|created|handling|number|shipmethod|shipping|shiptosameasbillto|
        shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|shiptoaddress3|
        shiptocity|shiptostate|shiptozip|shiptocountry|
        shiptodayphone|shiptonightphone|shiptofax|shiptoemail|
        subtotal|updated)$/x) {
            if ($context[$#context] eq 'new' && $tag !~ /^(count)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'add' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'results') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(order(s?))$/) {
                    return ");\n";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return ");\n";
                };
            };


        ## order item property tags
        ## order:sku, price, quantity
        } elsif ($tag =~ /^(sku|price|quantity|total)$/) {
            if ($context[$#context] eq 'add') {
                return ";\n";
            } elsif ($context[$#context] eq 'new') {
                return ";\n";
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'new') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'add') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'item') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'items') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'order') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'results' && $context[$#context-1] eq 'ordera') {
                $e->end_expr($tag);
            } elsif ($context[$#context] eq 'delete' && $tag !~ /^(count|subtotal)$/) {
                return ";\n";
            } elsif ($context[$#context] eq 'update') {
                if ($context[$#context-2] =~ /^(order(s?))$/) {
                    return ");\n";
                } elsif ($context[$#context-2] =~ /^(item(s?))$/) {
                    return ");\n";
                };
            };


        ## order:filter
        } elsif ($tag eq 'filter') {
            if ($context[$#context] eq 'order') {
                return ";\n";
            } elsif ($context[$#context] eq 'orders') {
                return ";\n";
            } elsif ($context[$#context] eq 'item') {
                return ";\n";
            } elsif ($context[$#context] eq 'items') {
                return ";\n";
            } elsif ($context[$#context] eq 'restore') {
                return ";\n";
            } elsif ($context[$#context] eq 'cart') {
                return ";\n";
            };


        ## order:results
        } elsif ($tag =~ /^result(s?)$/) {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'order') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'orders') {
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


        ## order:no-results
        } elsif ($tag =~ /^no-result(s?)$/) {
            if ($context[$#context-1] eq 'new') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'order') {
                pop @context;

                return "\n};\n";
            } elsif ($context[$#context-1] eq 'orders') {
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

AxKit::XSP::Handel::Order - AxKit XSP Order Taglib

=head1 SYNOPSIS

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::Handel::Order

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:order="http://today.icantfocus.com/CPAN/AxKit/XSP/Handel/Order"
    >

    <order:order type="1">
        <order:filter name="id"><request:idparam/></order:filter>
        <order:results>
            <order>
                <id><order:id/></id>
                <billto>
                    <firstname><order:billtofirstname/></firstname>
                    ...
                </billto>
                <shipto>
                    <firstname><order:shiptofirstname/></firstname>
                    ...
                </shipto>
                <total><order:total/></total>
                <subtotal><order:subtotal/></subtotal>
                <order:items>
                    <order:results>
                        <item>
                            <sku><order:sku/></sku>
                            <description><order:description/></description>
                            <quantity><order:quantity/></quantity>
                            <price><order:price/></price>
                            <total><order:total/></total>
                        </item>
                    </order:results>
                    </order:no-results>
                        <message>There are currently no items in your order.</message>
                    </order:no-results>
                </order:items>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head1 DESCRIPTION

This tag library provides an interface to use C<Handel::Order> inside of your
AxKit XSP pages.

=head1 TAG HIERARCHY

    <order:uuid/>
    <order:new process="0|1" cart|id|shopper|type|number|created|updated|comments|shipmethod|
               shipping|handling|tax|subtotal|total|
               billtofirstname|billtolastname|billtoaddress1|billtoaddress2|
               billtoaddress3|billtocity|billtostate|billtozip|
               billtocountry|billtodayphone|billtonightphone|billtofax|
               billtoemail|shiptosameasbillto|
               shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|
               shiptoaddress3|shiptocity|shiptostate|shiptozip|
               shiptocountry|shiptodayphone|shiptonightphone|shiptofax|
               shiptoemail="value"...>
        <order:cart description|id|name|shopper|type="value">
            <order:filter name="description|id|name|shopper|type">value</order:filter>
        </order:cart>
        <order:id>value</order:id>
        <order:shopper>value</order:shopper>
        <order:type>value</order:type>
        <order:number>value</order:number>
        <order:created>value</order:created>
        <order:updated>value</order:updated>
        <order:comments>value</order:comments>
        <order:shipmethod>value</order:shipmethod>
        <order:shipping>value</order:shipping>
        <order:handling>value</order:handling>
        <order:tax>value</order:tax>
        <order:subtotal>value</order:subtotal>
        <order:total>value</order:total>
        <order:billtofirstname>value</order:billtofirstname>
        <order:billtolastname>value</order:billtolastname>
        <order:billtoaddress1>value</order:billtoaddress1>
        <order:billtoaddress2>value</order:billtoaddress2>
        <order:billtoaddress3>value</order:billtoaddress3>
        <order:billtocity>value</order:billtocity>
        <order:billtostate>value</order:billtostate>
        <order:billtozip>value</order:billtozip>
        <order:billtocountry>value</order:billtocountry>
        <order:billtodayphone>value</order:billtodayphone>
        <order:billtonightphone>value</order:billtonightphone>
        <order:billtofax>value</order:billtofax>
        <order:billtoemail>value</order:billtoemail>
        <order:shiptosameasbillto>value</order:shiptosameasbillto>
        <order:shiptofirstname>value</order:shiptofirstname>
        <order:shiptolastname>value</order:shiptolastname>
        <order:shiptoaddress1>value</order:shiptoaddress1>
        <order:shiptoaddress2>value</order:shiptoaddress2>
        <order:shiptoaddress3>value</order:shiptoaddress3>
        <order:shiptocity>value</order:shiptocity>
        <order:shiptostate>value</order:shiptostate>
        <order:shiptozip>value</order:shiptozip>
        <order:shiptocountry>value</order:shiptocountry>
        <order:shiptodayphone>value</order:shiptodayphone>
        <order:shiptonightphone>value</order:shiptonightphone>
        <order:shiptofax>value</order:shiptofax>
        <order:shiptoemail>value</order:shiptoemail>

        <order:results>
            <order:id>value</order:id>
            <order:shopper>value</order:shopper>
            <order:type>value</order:type>
            <order:number>value</order:number>
            <order:created>value</order:created>
            <order:updated>value</order:updated>
            <order:comments>value</order:comments>
            <order:shipmethod>value</order:shipmethod>
            <order:shipping
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
            <order:handling
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
            <order:tax
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
            <order:subtotal
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
            <order:total
                format="0|1"
                code="USD|CAD|..."
                options="FMT_STANDARD|FMT_NAME|..."
                convert="0|1"
                from="USD|CAD|..."
                to="CAD|JPY|..."
            />
            <order:billtofirstname>value</order:billtofirstname>
            <order:billtolastname>value</order:billtolastname>
            <order:billtoaddress1>value</order:billtoaddress1>
            <order:billtoaddress2>value</order:billtoaddress2>
            <order:billtoaddress3>value</order:billtoaddress3>
            <order:billtocity>value</order:billtocity>
            <order:billtostate>value</order:billtostate>
            <order:billtozip>value</order:billtozip>
            <order:billtocountry>value</order:billtocountry>
            <order:billtodayphone>value</order:billtodayphone>
            <order:billtonightphone>value</order:billtonightphone>
            <order:billtofax>value</order:billtofax>
            <order:billtoemail>value</order:billtoemail>
            <order:shiptosameasbillto>value</order:shiptosameasbillto>
            <order:shiptofirstname>value</order:shiptofirstname>
            <order:shiptolastname>value</order:shiptolastname>
            <order:shiptoaddress1>value</order:shiptoaddress1>
            <order:shiptoaddress2>value</order:shiptoaddress2>
            <order:shiptoaddress3>value</order:shiptoaddress3>
            <order:shiptocity>value</order:shiptocity>
            <order:shiptostate>value</order:shiptostate>
            <order:shiptozip>value</order:shiptozip>
            <order:shiptocountry>value</order:shiptocountry>
            <order:shiptodayphone>value</order:shiptodayphone>
            <order:shiptonightphone>value</order:shiptonightphone>
            <order:shiptofax>value</order:shiptofax>
            <order:shiptoemail>value</order:shiptoemail>


            <order:add id|sku|quantity|price|description|total="value"...>
                <order:description>value</order:description>
                <order:id>value</order:id>
                <order:sku>value</order:sku>
                <order:quantity>value</order:quantity>
                <order:price>value</order:price>
                <order:total>value</order:total>
                <order:results>
                    <order:description/>
                    <order:id/>
                    <order:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <order:quantity/>
                    <order:sku/>
                    <order:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                </order:results>
                <order:no-results>
                    ...
                </order:no-results>
            </order:add>
        </order:results>
        <order:no-results>
            ...
        <order:no-results>
    </order:new>
    <order:order(s) id|shopper|type|number|created|updated|comments|shipmethod|
               shipping|handling|tax|subtotal|total|
               billtofirstname|billtolastname|billtoaddress1|billtoaddress2|
               billtoaddress3|billtocity|billtostate|billtozip|
               billtocountry|billtodayphone|billtonightphone|billtofax|
               billtoemail|shiptosameasbillto|
               shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|
               shiptoaddress3|shiptocity|shiptostate|shiptozip|
               shiptocountry|shiptodayphone|shiptonightphone|shiptofax|
               shiptoemail="value"...>
        <order:filter name="id|shopper|type|number|created|updated|comments|shipmethod|
               shipping|handling|tax|subtotal|total|
               billtofirstname|billtolastname|billtoaddress1|billtoaddress2|
               billtoaddress3|billtocity|billtostate|billtozip|
               billtocountry|billtodayphone|billtonightphone|billtofax|
               billtoemail|shiptosameasbillto|
               shiptofirstname|shiptolastname|shiptoaddress1|shiptoaddress2|
               shiptoaddress3|shiptocity|shiptostate|shiptozip|
               shiptocountry|shiptodayphone|shiptonightphone|shiptofax|
               shiptoemail">value</order:filter>
        <order:results>
            <order:add description|id|price|quantity|sku|total="value"...>
                <order:description>value</order:description>
                <order:id>value</order:id>
                <order:price>value</order:price>
                <order:quantity>value</order:quantity>
                <order:sku>value</order:sku>
                <order:total></order:total>
                <order:results>
                    <order:description/>
                    <order:id/>
                    <order:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <order:quantity/>
                    <order:sku/>
                    <order:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                </order:results>
                </order:no-results>
                    ...
                </order:no-results>
            </order:add>
            <order:clear/>
            <order:count/>
            <order:delete description|id|price|quantity|sku|total="value"...>
                <order:description>value</order:description>
                <order:id>value</order:id>
                <order:price>value</order:price>
                <order:quantity>value</order:quantity>
                <order:sku>value</order:sku>
                <order:total>value</order:total>
            </order:delete>
            <order:description/>
            <order:id/>
            <order:item(s) description|id|price|quantity|sku|total="value"...>
                <order:filter name="description|id|price|quantity|sku|total">value</order:filter>
                <order:results>
                    <order:description/>
                    <order:id/>
                    <order:price
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <order:quantity/>
                    <order:sku/>
                    <order:total
                        format="0|1"
                        code="USD|CAD|..."
                        options="FMT_STANDARD|FMT_NAME|..."
                        convert="0|1"
                        from="USD|CAD|..."
                        to="CAD|JPY|..."
                    />
                    <order:update>
                        <order:description>value</order:description>
                        <order:price>value</order:price>
                        <order:quantity>value</order:quantity>
                        <order:sku>value</order:sku>
                        <order:total>value</order:total>
                    </order:update>
                </order:results>
                <order:no-results>
                    ...
                </order:no-results>
            </order:item(s)>
            <order:update>
                <order:shopper>value</order:shopper>
                <order:type>value</order:type>
                <order:number>value</order:number>
                <order:created>value</order:created>
                <order:updated>value</order:updated>
                <order:comments>value</order:comments>
                <order:shipmethod>value</order:shipmethod>
                <order:shipping>value</order:shipping>
                <order:handling>value</order:handling>
                <order:tax>value</order:tax>
                <order:subtotal>value</order:subtotal>
                <order:total>value</order:total>
                <order:billtofirstname>value</order:billtofirstname>
                <order:billtolastname>value</order:billtolastname>
                <order:billtoaddress1>value</order:billtoaddress1>
                <order:billtoaddress2>value</order:billtoaddress2>
                <order:billtoaddress3>value</order:billtoaddress3>
                <order:billtocity>value</order:billtocity>
                <order:billtostate>value</order:billtostate>
                <order:billtozip>value</order:billtozip>
                <order:billtocountry>value</order:billtocountry>
                <order:billtodayphone>value</order:billtodayphone>
                <order:billtonightphone>value</order:billtonightphone>
                <order:billtofax>value</order:billtofax>
                <order:billtoemail>value</order:billtoemail>
                <order:shiptosameasbillto>value</order:shiptosameasbillto>
                <order:shiptofirstname>value</order:shiptofirstname>
                <order:shiptolastname>value</order:shiptolastname>
                <order:shiptoaddress1>value</order:shiptoaddress1>
                <order:shiptoaddress2>value</order:shiptoaddress2>
                <order:shiptoaddress3>value</order:shiptoaddress3>
                <order:shiptocity>value</order:shiptocity>
                <order:shiptostate>value</order:shiptostate>
                <order:shiptozip>value</order:shiptozip>
                <order:shiptocountry>value</order:shiptocountry>
                <order:shiptodayphone>value</order:shiptodayphone>
                <order:shiptonightphone>value</order:shiptonightphone>
                <order:shiptofax>value</order:shiptofax>
                <order:shiptoemail>value</order:shiptoemail>
            </order:update>
        </order:results>
        <order:no-results>
            ...
        </order:no-results>
    </order:order(s)>

=head1 TAG REFERENCE

=head2 <order:add>

Adds an a item to the current order. You can specify the item properties as
attributes in the tag itself:

    <order:add
        description="My New Part"
        id="11111111-1111-1111-1111-111111111111"
        sku="1234"
        quantity="1"
        price="1.23"
        total="1.23"
    />

or you can add them as child elements:

    <order:add>
        <order:description>My New Part</order:description>
        <order:id>11111111-1111-1111-1111-111111111111</order:id>
        <order:sku>1234</order:sku>
        <order:quantity>1</order:quantity>
        <order:price>1.23</order:price>
        <order:total>1.23</order:total>
    </order:add>

or any combination of the two:

    <order:add quantity="1">
        <order:description>My New Part</order:description>
        <order:id>11111111-1111-1111-1111-111111111111</order:id>
        <order:sku>1234</order:sku>
        <order:price>1.23</order:price>
        <order:total>1.23</order:total>
    </order:add>

This tag is only valid within the C<E<lt>order:resultsE<gt>> block for C<order>
and C<orders>. See C<Handel::Order> for more information about adding parts to
the order.

You can also access the newly added item using the C<E<lt>order:resultsE<gt>>.

=head2 <order:billtofirstname>

Context aware tag that gets or sets the bill to address first name.

=head2 <order:billtolastname>

Context aware tag that gets or sets the bill to address last name.

=head2 <order:billtoaddress1>

Context aware tag that gets or sets the bill to address line 1.

=head2 <order:billtoaddress2>

Context aware tag that gets or sets the bill to address line 2.

=head2 <order:billtoaddress3>

Context aware tag that gets or sets the bill to address line 3.

=head2 <order:billtocity>

Context aware tag that gets or sets the bill to address city.

=head2 <order:billtostate>

Context aware tag that gets or sets the bill to address state.

=head2 <order:billtozip>

Context aware tag that gets or sets the bill to address zip or postal code.

=head2 <order:billtocountry>

Context aware tag that gets or sets the bill to address country.

=head2 <order:billtodayphone>

Context aware tag that gets or sets the bill to address date time phone number.

=head2 <order:billtonightphone>

Context aware tag that gets or sets the bill to address night time phone number.

=head2 <order:billtofax>

Context aware tag that gets or sets the bill to address fax number.

=head2 <order:billtoemail>

Context aware tag that gets or sets the bill to email address.

=head2 <order:clear>

Deletes all items in the current order.

    <order:order type="0">
        <order:filter name="shopper">11111111-1111-1111-1111-111111111111</order:filter>
        <order:results>
            <order:clear/>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:comments>

Context aware tag that gets or sets the orders comments.

=head2 <order:count>

Returns the number of items in the current order.

    <order:order>
        <order:results>
            <order>
                <id><order:id/></id>
                <subtotal><order:subtotal/></subtotal>
                <count><order:count/></count>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:created>

Context aware tag that gets or sets the order creation date.

=head2 <order:description>

Context aware tag to get or set the description of various other parent tags.
Within C<E<lt>order:addE<gt>> or C<E<lt>order:updateE<gt>> it sets the current
order items description:

    <order:order>
        <order:results>
            <order:add>
                <order:description>My New SKU Description</order:description>
            </order:add>

            <order:item sku="1234">
                <order:results>
                    <description><order:description/></description>
                    <order:update>
                        <order:description>My Updated SKU Description</order:description>
                    <order:update>
                </order:results>
                <order:no-results>
                    <message>The order item could not be found for updating</message>
                </order:no-results>
            <order:item>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:filter>

Adds a new name/value pair to the filter used in C<E<lt>order:orderE<gt>>,
C<E<lt>order:ordersE<gt>>, C<E<lt>order:deleteE<gt>>, C<E<lt>order:itemE<gt>>,
C<E<lt>order:cart<gt>>, and C<E<lt>order:itemsE<gt>>. Pass the name of the pair
in the C<name> attribute and the value between the start and end filter tags:

    <order:order type="0">
        <order:filter name="id">12345678-9098-7654-3212-345678909876</order:filter>

        <order:results>
            <order:delete>
                <order:filter name="sku">sku1234</order:filter>
            <order:delete>
        </order:results>
        <order:no-results>
            <message>The order item could not be found for deletion</message>
        </order:no-results>
    </order:order>

If the same attribute is specified in a filter, the child filter tag value
takes precedence over the parent tags attribute.

    <order:order type="0">
        <!-- type == 0 -->
        <order:filter name="type">1</order:filter>
        <!-- type == 1 -->
    </order:order>

You can supply as many C<filter>s as needed to get the job done.

    <order:order>
        <order:filter name="type">0</order:filter>
        <order:filter name="shopper">12345678-9098-7654-3212-345678909876</order:filter>
    </order:order>

=head2 <order:handling>

Context aware tag the gets or sets the handling charge for this order.

=head2 <order:id>

Context aware tag to get or set the record id within various other tags.
In C<E<lt>order:orderE<gt>> and C<E<lt>order:itemE<gt>> it returns the
record id for the object:

    <order:order>
        <order:results>
            <id><order:id/></id>
            <order:items>
                <order:order:results>
                    <item>
                        <id><order:id/></id>
                    </item>
                </order:results>
            </order:items>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

Within C<E<lt>order:addE<gt>>, C<E<lt>order:deleteE<gt>>, and
C<E<lt>order:newE<gt>> it sets the id value used in the operation specified:

    <order:order>
        <order:results>
            <order:delete>
                <order:id>11111111-1111-1111-1111-111111111111</order:id>
            </order:delete>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>
    ...
    <order:new>
        <order:id>11112222-3333-4444-5555-6666777788889999</order:id>
        <order:name>New Cart</order:name>
    </order:new>

It cannot be used within C<E<lt>order:updateE<gt>> and will return a
C<Handel::Exception::Taglib> exception if you try updating
the record ids which are the primary keys.

=head2 <order:items>

Loops through all items in the current order:

    <order:order>
        <order:results>
            <order>
                <order:items>
                    <order:results>
                        <item>
                            <sku><order:sku/></sku>
                            <description><order:description/></order:description>
                            <name><order:name/></name>
                            <quantity><order:quantity/></quantity>
                            <price><order:price/></price>
                            <total><order:total/></total>
                        </item>
                    </order:results>
                    <order:no-results>
                        <message>Your order is empty</message>
                    </order:no-results>
                </order:items>
            <order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:new>

B<BREAKING API CHANGE:> Starting in version 0.17_04, new no longer automatically
creates a checkout process for C<CHECKOUT_PHASE_INITIALIZE>. The C<$noprocess>
parameter has been renamed to C<$process>. The have the new order automatically
run a checkout process, set $process to 1.

Creates a new order using the supplied attributes and child tags:

    <order:new process="0|1" type="1">
        <order:id>22222222-2222-2222-2222-222222222222</order:id>
        <order:shopper><request:shopper/></order:shopper>
        <order:name>New Cart</order:name>
    </order:new>

The child tags take precedence over the attributes of the same name.
C<new> B<must be a top level tag> within it's declared namespace.
It will throw an C<Handel::Exception::Taglib> exception otherwise.

When true, the C<process> attribute forces new to automaticly create
a checkout process and initialize the currecnt order.
See L<Handel::Order/"new"> for more informaiton on the process flag.

=head2 <order:number>

Context aware tag that gets or sets the order numnber.

=head2 <order:order>

Container tag for the current order used to load a specific order.

If C<order> or its C<filter>s load more than one order, C<order> will contain only
the first order. If you're looking for loop through multiple orders, try
C<E<lt>order:ordersE<gt>> instead.

    <order:order type="1">
        <order:filter name="id">11111111-1111-1111-1111-111111111111</order:filter>
        <order:results>
            <order>
                <id><order:id/></id>
                <billto>
                    <name><order:billtofirstname/> <order:billtolastname/></name>
                    ...
                </billto>
                <subtotal><order:subtotal/></subtotal>
                <order:items>
                    ...
                </order:items>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:orders>

Loops through all loaded orders.

        <order:orders type="1">
            <order:filter name="shopper">11111111-1111-1111-1111-111111111111</order:filter>
            <order:results>
                <order>
                    <id><order:id/></id>
                    <created><order:created/></created>
                    <total><order:subtotal/></total>
                    <order:items>
                        ...
                    </order:items>
                </order>
            </order:results>
            <order:no-results>
                <message>No orders were found matching your query.</message>
            </order:no-results>
        </order:orders>
    </orders>

=head2 <order:price>

Context aware tag to get or set the price of a order item.
In C<E<lt>order:addE<gt>> and C<E<lt>order:updateE<gt>>
it sets the price:

    <order:order>
        <order:results>
            <order:add>
                <order:price>1.24</order:price>
            </order:add>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

In C<E<lt>order:itemE<gt>> or C<E<lt>order:itemsE<gt>> it returns the price
for the order item:

    <order:order>
        <order:results>
            <order>
                <order:items>
                    <order:results>
                        <item>
                            <price><order:price/></price>
                        </item>
                    </order:results>
                    <order:no-results>
                        <message>Your shopping order is empty</message>
                    </order:no-results>
                </order:items>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head3 Currency Formatting

The currency formatting options from
C<Handel::Currency> are now available within the taglib if
C<Locale::Currency::Format> is installed.

     <order:price format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

Currency formatting is available for any tag the returns a currency or price like
price, total, shipping, handling, tax, etc.

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

The currency conversion options from
C<Handel::Currency> are now available within the taglib if
C<Finance::Currency::Convert::WebserviceX> is installed.

    <order:price convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />

Currency conversion is available for any tag the returns a currency or price like
price, total, shipping, handling, tax, etc.

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

=head2 <order:quantity>

Context aware tag to get or set the quantity of a order item.
In C<E<lt>order:addE<gt>> and C<E<lt>order:updateE<gt>> it sets the quantity:

    <order:order>
        <order:results>
            <order:add>
                <order:quantity>1.24</order:quantity>
            </order:add>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

In C<E<lt>order:itemE<gt>> or C<E<lt>order:itemsE<gt>> it returns the quantity
for the order item:

    <order:order>
        <order:results>
            <order>
                <order:items>
                    <order:results>
                        <item>
                            <quantity><order:quantity/></quantity>
                        </item>
                    </order:results>
                    <order:no-results>
                        <message>The item requested could not be found for updating</message>
                    </order:no-results>
                </order:items>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:updated>

COntext aware tag that gets or sets the order last updated date.

=head2 <order:update>

Updates the current order values:

    <order:order>
        <order:results>
            <order:update>
                <order:type>ORDER_TYPE_TEMP</order:update>
            <order:update>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

C<E<lt>order:idE<gt>> is not valid within an update statement.

=head2 <order:results>

Contains the results for the current action. both the singular and plural
forms are valid for your syntactic sanity:

    <order:order>
        <order:result>
            ...
        </order:result>
    </order:result>

    <order:orders>
        <order:results>

        </order:results>
    </order:orders>

=head2 <order:no-results>

The anti-results or 'not found' tag. This tag is executed when
C<order>, C<orders>, C<item>, or C<items> fails to fild a match for it's filters.
As with C<E<lt>order:resultsE<gt>>, both the
singular and plural forms are available for your enjoyment:

    <order:order>
        <order:no-result>
            ...
        </order:no-result>
    </order:result>

    <order:orders>
        <order:no-results>

        </order:no-results?
    </order:orders>

=head2 <order:shiptofirstname>

Context aware tag that gets or sets the ship to address first name.

=head2 <order:shiptolastname>

Context aware tag that gets or sets the ship to address last name.

=head2 <order:shiptoaddress1>

Context aware tag that gets or sets the ship to address line 1.

=head2 <order:shiptoaddress2>

Context aware tag that gets or sets the ship to address line 2.

=head2 <order:shiptoaddress3>

Context aware tag that gets or sets the ship to address line 3.

=head2 <order:shiptocity>

Context aware tag that gets or sets the ship to address city.

=head2 <order:shiptostate>

Context aware tag that gets or sets the ship to address state.

=head2 <order:shiptozip>

Context aware tag that gets or sets the ship to address zip or postal code.

=head2 <order:shiptocountry>

Context aware tag that gets or sets the ship to address country.

=head2 <order:shiptodayphone>

Context aware tag that gets or sets the ship to address date time phone number.

=head2 <order:shiptonightphone>

Context aware tag that gets or sets the ship to address night time phone number.

=head2 <order:shiptofax>

Context aware tag that gets or sets the ship to address fax number.

=head2 <order:shiptoemail>

Context aware tag that gets or sets the ship to email address.

=head2 <order:shipmethod>

Context aware tag that gets or sets the selected shipping method.

=head2 <order:shipping>

Context aware tag that gets or sets the shipping cost.

=head2 <order:shiptosameasbillto>

Context aware tag that gets or sets the flag making the ship to address the
same as the bill to address.

=head2 <order:shopper>

Context aware tag that gets or sets the shopper id for the current order.

=head2 <order:sku>

Context aware tag to get or set the sku of a order item.
In C<E<lt>order:addE<gt>> and C<E<lt>order:updateE<gt>> it sets the sku:

    <order:order>
        <order:results>
            <order:add>
                <order:sku>sku1234</order:sku>
            </order:add>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

In C<E<lt>order:itemE<gt>> or C<E<lt>order:itemsE<gt>> it returns the sku
for the current order item:

    <order:order>
        <order:results>
            <order>
                <order:items>
                        <order:results>
                            <item>
                                <sku><order:sku/></sku>
                            </item>
                        </order:results>
                        <order:no-results>
                            <message>Your shopping order is empty</message>
                        </order:no-results>
                </order:items>
            </order>
        <order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

=head2 <order:subtotal>

Gets or sets the subtotal of the items in the current order:

    <order:order>
        <order:results>
            <subtotal><order:subtotal/></subtotal>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

The currency formatting options from
C<Handel::Currency> are now available within the taglib.

     <order:subtotal format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

The currency conversion options from
C<Handel::Currency> are now available within the taglib.

    <order:subtotal convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />

See <order:price> above for further details about price formatting.

=head2 <order:tax>

Gets or sets the order tax charge.

=head2 <order:total>

Gets or sets the total of the current order item:

    <order:order>
        <order:results>
            <order>
                <order:items>
                    <order:results>
                        <item>
                            <total><order:total/></total>
                        </item>
                    </order:results>
                    <order:no-results>
                        <message>Your shopping order is empty</message>
                    </order:no-results>
                </order:items>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

The currency formatting options from
C<Handel::Currency> are now available within the taglib.

     <order:total format="0|1" code="USD|CAD|..." options="FMT_STANDARD|FMT_NAME|..." />

The currency conversion options from
C<Handel::Currency> are now available within the taglib.

    <order:total convert="0|1" from="USD|CAD|..." to="CAD|JPY|..." />


See <order:price> above for further details about price formatting.

=head2 <order:type>

Context aware tag to get or set the type within various other tags.
In C<E<lt>order:orderE<gt>> or C<E<lt>order:ordersE<gt>> it returns the
type for the object:

    <order:order>
        <order:results>
            <order>
                <type><order:type/></type>
            </order>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>

Within C<E<lt>order:updateE<gt>> and C<E<lt>order:newE<gt>>
it sets the type value used in the operation specified:

    <order:order>
        <order:results>
            <order:update>
                <order:type>1</order:type>
            </order:update>
        </order:results>
        <order:no-results>
            <message>The order requested could not be found.</message>
        </order:no-results>
    </order:order>
    ...
    <order:new>
        <order:type>1</order:type>
    </order:new>

=head2 <order:uuid/>

This tag returns a new uuid/guid for use in C<new> and C<add> in the
following format:

    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

For those like me who always type the wrong thing, C<E<lt>order:guid/<gt>>
returns the same things as C<E<lt>order:uuid/<gt>>.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
