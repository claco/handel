# $Id$
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Cart;
    use Handel::Checkout::Stash;
    use Handel::Constants qw(:checkout :returnas);
    use Handel::Constraints qw(constraint_checkout_phase constraint_uuid);
    use Handel::Exception qw(:try);
    use Handel::Checkout::Message;
    use Handel::L10N qw(translate);
    use Handel::Order;
    use Module::Pluggable 2.95 instantiate => 'new', sub_name => '_plugins';
    use base qw(Class::Data::Inheritable);

    __PACKAGE__->mk_classdata(_order_class => 'Handel::Order');
    __PACKAGE__->mk_classdata(_stash_class => 'Handel::Checkout::Stash');
};

sub new {
    my $class = shift;
    my $opts = shift || {};
    my $self = bless {
        plugins => [],
        handlers => {},
        phases => [],
        messages => [],
        stash => $opts->{'stash'} || $class->stash_class->new
    }, ref $class || $class;

    $self->_set_search_path($opts);

    foreach ($self->_plugins($self)) {
        if (UNIVERSAL::isa($_, 'Handel::Checkout::Plugin')) {
            push @{$self->{'plugins'}}, $_;
            $_->register($self);
        };
    };

    $self->cart($opts->{'cart'}) if $opts->{'cart'};
    $self->order($opts->{'order'}) if $opts->{'order'};
    $self->phases($opts->{'phases'}) if $opts->{'phases'};

    return $self;
};

sub plugins {
    my $self = shift;

    return wantarray ? sort @{$self->{'plugins'}} : $self->{'plugins'};
};

sub add_handler {
    my ($self, $phase, $ref, $preference) = @_;
    my ($package) = caller;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a a valid CHECKOUT_PHASE_* value') . '.')
            unless constraint_checkout_phase($phase);

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a CODE reference') . '.')
            unless ref($ref) eq 'CODE';

    foreach (@{$self->{'plugins'}}) {
        if (ref $_ eq $package) {
            if ($preference) {
                if (exists $self->{'handlers'}->{$phase}->{$preference}) {
                    my $plugin = $self->{'handlers'}->{$phase}->{$preference}->[0];

                    throw Handel::Exception::Checkout( -details =>
                        translate("There is already a handler in phase ([_1]) for preference ([_2]) from the plugin ([_3])", $phase, $preference, $plugin) . '.')
                };
            } else {
                my @prefs = sort {$a <=> $b} keys %{$self->{'handlers'}->{'$phase'}};
                $preference = scalar @prefs ? $#prefs++ : 101;
            };
            $self->{'handlers'}->{$phase}->{$preference} = [$_, $ref];
            last;
        };
    };
};

sub add_message {
    my ($self, $message) = @_;
    my ($package, $filename, $line) = caller;

    if (ref $message && UNIVERSAL::isa($message, 'Handel::Checkout::Message')) {
        $message->package($package) unless $message->package;
        $message->filename($filename) unless $message->filename;
        $message->line($line) unless $message->line;

        push @{$self->{'messages'}}, $message;
    } elsif (!ref $message || ref $message eq 'Apache::AxKit::Exception::Error') {
        push @{$self->{'messages'}}, Handel::Checkout::Message->new(
            text => $message, source => $package, filename => $filename, line => $line);
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not a Handel::Checkout::Message object or text message') . '.');
    };
};

sub add_phase {
    my ($self, $name, $value, $import) = @_;
    my $caller = (caller);

    if (Handel::Constants->can($name)) {
        throw Handel::Exception::Constraint(
            -text => translate("A constant named '$name' already exists in Handel::Constants")
        );
    } elsif (constraint_checkout_phase($value)) {
        throw Handel::Exception::Constraint(
            -text => translate("A phase constant value of '$value' already exists")
        );
    } elsif ($import && main->can($name)) {
        throw Handel::Exception::Constraint(
            -text => translate("A constant named '$name' already exists in caller '$caller'")
        );
    } else {
        my $sub = sub {return $value};
        no strict 'refs';

        *{"Handel::Constants::$name"} = $sub;

        if ($import) {
            *{"${caller}::$name"} = $sub;
        };

        push @Handel::Constants::CHECKOUT_ALL_PHASES, $value;
    };
};

sub clear_messages {
    my $self = shift;

    $self->{'messages'} = [];
};

sub cart {
    my ($self, $cart) = @_;

    if ($cart) {
        if (ref $cart eq 'HASH' || UNIVERSAL::isa($cart, 'Handel::Cart') || constraint_uuid($cart)) {
            $self->order($self->order_class->new({cart => $cart}));
        } else {
            throw Handel::Exception::Argument( -details =>
                translate('Param 1 is not a HASH reference, Handel::Cart object, or cart id') . '.');
        };
    };
};

sub messages {
    my $self = shift;

    return wantarray ? @{$self->{'messages'}} : $self->{'messages'};
};

sub order_class {
    my ($self, $order_class) = @_;

    if ($order_class) {
        eval "require $order_class";
        $self->_order_class($order_class);
    };

    return $self->_order_class;
};

sub order {
    my ($self, $order) = @_;

    if ($order) {
        if (ref $order eq 'HASH') {
            $self->{'order'} = $self->order_class->load($order, RETURNAS_ITERATOR)->first;
        } elsif (UNIVERSAL::isa($order, 'Handel::Order')) {
            $self->{'order'} = $order;
        } elsif (constraint_uuid($order)) {
            $self->{'order'} = $self->order_class->load({id => $order});
        } else {
            throw Handel::Exception::Argument( -details =>
                translate('Param 1 is not a HASH reference, Handel::Order object, or order id') . '.');
        }
    } else {
        return $self->{'order'};
    };
};

sub phases {
    my ($self, $phases) = @_;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not an ARRAY reference or string') . '.') unless (ref($phases) eq 'ARRAY' || !ref($phases));

        if (! ref $phases) {
            # holy crap, that actually worked!
            $phases = [map(eval "$_", _path_to_array($phases))];
        };

        $self->{'phases'} = $phases;
    } else {
        if (wantarray) {
            return (scalar @{$self->{'phases'}}) ? @{$self->{'phases'}} : @{&CHECKOUT_DEFAULT_PHASES};
        } else {
            return (scalar @{$self->{'phases'}}) ? $self->{'phases'} : &CHECKOUT_DEFAULT_PHASES;
        };
    };
};

sub process {
    my $self = shift;
    my $phases = shift;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate(
                'Param 1 is not an ARRAY reference or string') . '.')
                unless (ref($phases) eq 'ARRAY' || ! ref($phases));

        if (! ref $phases) {
            # holy crap, that actually worked!
            $phases = [map(eval "$_", _path_to_array($phases))];
        };
    } else {
        $phases = $self->{'phases'} || CHECKOUT_DEFAULT_PHASES;
    };

    throw Handel::Exception::Checkout( -details =>
        translate('No order is assocated with this checkout process') . '.')
            unless $self->order;

    $self->stash->clear;
    $self->_setup($self);

    {
        local $self->order->db_Main->{AutoCommit};

        foreach my $phase (@{$phases}) {
            next unless $phase;

            my @handlerprefs = sort {$a <=> $b} keys %{$self->{'handlers'}->{$phase}};
            foreach my $handlerpref (@handlerprefs) {
                my $handler = $self->{'handlers'}->{$phase}->{$handlerpref};
                my $status = $handler->[1]->($handler->[0], $self);

                if ($status != CHECKOUT_HANDLER_OK && $status != CHECKOUT_HANDLER_DECLINE) {
                    $self->_teardown($self);

                    eval {$self->order->dbi_rollback};
                    if ($@) {
                        throw Handel::Exception(-details => "Transaction aborted. Rollback failed: $@");
                    };

                    return CHECKOUT_STATUS_ERROR;
                };
            };
        };

        $self->order->dbi_commit;
    };

    $self->_teardown($self);

    return CHECKOUT_STATUS_OK;
};

sub stash_class {
    my ($self, $stash_class) = @_;

    if ($stash_class) {
        eval "require $stash_class";
        $self->_stash_class($stash_class);
    };

    return $self->_stash_class;
};

sub stash {
    my $self = shift;

    return $self->{'stash'};
};

sub _setup {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->setup($self);
        } otherwise {
            warn shift->text;
        };
    };
};

sub _teardown {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->teardown($self);
        } otherwise {
            warn shift->text;
        };
    };
};

sub _set_search_path {
    my ($self, $opts) = @_;
    my $config = $Handel::Cfg;

    my $pluginpaths = ref $opts->{'pluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'pluginpaths'}}) : $opts->{'pluginpaths'} || '';

    my $addpluginpaths = ref $opts->{'addpluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'addpluginpaths'}}) : $opts->{'addpluginpaths'} || '' ;

    if ($pluginpaths) {
        $self->search_path(new => _path_to_array($pluginpaths));
    } elsif (my $path = $config->{'HandelPluginPaths'}) {
        $self->search_path(new => _path_to_array($path));
    } elsif ($path = $config->{'HandelAddPluginPaths'} || $addpluginpaths) {
        $self->search_path(new => 'Handel::Checkout::Plugin', _path_to_array("$path $addpluginpaths"));
    };

    ## reset these crazy things
    $self->except([]);
    $self->only([]);

    my $ignore = $opts->{'ignoreplugins'} || $config->{'HandelIgnorePlugins'};
    if (ref $ignore eq 'Regexp' || ref $ignore eq 'ARRAY') {
        $self->except($ignore);
    } elsif ($ignore) {
        $self->except([_path_to_array($ignore)]);
    };

    my $only = $opts->{'loadplugins'} || $config->{'HandelLoadPlugins'};
    if (ref $only eq 'Regexp' || ref $only eq 'ARRAY') {
        $self->only($only);
    } elsif ($only) {
        $self->only([_path_to_array($only)]);
    };

    return undef;
};

sub _path_to_array {
    my $path = shift or return '';

    # ditch begin/end space, replace comma with space and
    # split on space
    $path =~ s/(^\s+|\s+$)//;
    $path =~ s/,/ /g;

    return split /\s+/, $path;
};

1;
__END__

=head1 NAME

Handel::Checkout - Checkout Pipeline Processor

=head1 SYNOPSIS

    use Handel::Checkout;

    my $checkout = Handel::Checkout->new({
        cart    => '122345678-9098-7654-3212-345678909876',
        phases  => [CHECKOUT_PHASE_INITIALIZE, CHECKOUT_PHASE_VALIDATE]
    });

    if ($checkout->process == CHECKOUT_STATUS_OK) {
        print 'Your order number is ', $checkout->order->number;
    } else {
        ...
    };

=head1 DESCRIPTION

Handel::Checkout is a basic pipeline processor that uses plugins at
various phases to perform any work necessary from credit card authorization
to order delivery. Handel does not try to be all things to all people
needing to place online orders. Instead, it provides a basic plugin mechanism
allowing the checkout process to be customized for many different needs.

=head1 CONSTRUCTOR

=head2 new([\%options])

Creates a new checkout pipeline process and loads all available plugins.
C<new> accepts the following options in an optional HASH reference:

=over

=item cart

A HASH reference, Handel::Cart object, or a cart id. This will be loaded
into a new Handel::Order object and associated with the new checkout
process.

See C<cart> below for further details about the various values allowed
to be passed.

B<Note>: When creating a new order via Handel::Order, C<new> will automatically
create a checkout process and process the C<CHECKOUT_PHASE_INITIALIZE>.
However, when a new order is created using C<cart> in Handel::Checkout, the
automatic processing of C<CHECKOUT_PHASE_INITIALIZE> is disabled.

=item order

A HASH reference, Handel::Order object, or an order id. This will be loaded
and associated with the new checkout process.

See C<order> below for further details about the various values allowed
to be passed.

=item pluginpaths

An array reference or a comma (or space) separated list containing the various
namespaces of plugins to be loaded. This will override any settings in
C<ENV> or F<httpd.conf> for the current checkout instance only.

    my $checkout = Handel::Checkout->new({
        pluginpaths => [MyNamespace::Plugins, Other::Plugin]
    });

    my $checkout = Handel::Checkout->new({
        pluginpaths => 'MyNamespace::Plugins, Other::Plugin'
    });

See L<"HandelPluginPaths"> for more information about settings/resetting
plugin search paths.

=item addpluginpaths

An array reference or a comma (or space) separated list containing the various
namespaces of plugin paths in addition to Handel::Checkout::Plugin to be loaded.
If C<HandelAddPluginPaths> is also specified, the two will be combined.

    my $checkout = Handel::Checkout->new({
        addpluginpaths => [MyNamespace::Plugins, Other::Plugin]
    });

    my $checkout = Handel::Checkout->new({
        addpluginpaths => 'MyNamespace::Plugins, Other::Plugin'
    });

See L<"HandelAddPluginPaths"> for more information about settings/resetting
plugin search paths.

=item loadplugins

An array reference or a comma (or space) separated list containing the
names of the specific plugins to load in the current plugin paths.

See L<"HandelLoadPlugins"> for more information about loading specific
plugins.

=item ignoreplugins

An array reference or a comma (or space) separated list containing the
names of the specific plugins to be ignored (not loaded)
in the current plugin paths.

See L<"HandelIgnorePlugins"> for more information about ignore specific
plugins.

=item phases

An array reference or a comma (or space) separated list containing the
various phases to be executed.

    my $checkout = Handel::Checkout->new({
        phases => [CHECKOUT_PHASE_VALIDATION,
                   CHECKOUT_PHASE_AUTHORIZATION]
    });

    my $checkout = Handel::Checkout->new({
        phases => 'CHECKOUT_PHASE_VALIDATION, CHECKOUT_PHASE_AUTHORIZATION'
    });

=item stash

A Handel::Checkout::Stash instance of subclass instance. If nothing is specified,
$self->stash_class will be used instead.

=back

=head1 METHODS

=head2 add_handler($phase, \&coderef, $preference)

Registers a code reference with the checkout phase specified and assigned a run
order preference. This is usually called within C<register> on the current
checkout context:

    sub register {
        my ($self, $ctx) = @_;

        $ctx->add_handler(CHECKOUT_PHASE_DELIVER, \&myhandler, 200);
    };

    sub myhandler {
        ...
    };

If no preference number is specified, the handler is added to the end of the
list after all other handlers in that phase.

If there is already a handler in the specified phase with the same preference, a
Handel::Exception::Checkout exception will be thrown.

While not enforced, please keep your handler preference orders between 251 - 749.
Preference orders 1-250 and 750-1000 will be reserved for core modules that need
to run before or after all other plugin handlers.

=head2 add_message($message)

Adds a new text message or Handel::Checkout::Message based object
to the message stack so plugins can log their issues for later inspection.

    sub handler {
        my ($self, $ctx) = @_;
        ...
        $ctx->add_message('Skipping phase for countries other than US...');

        return CHECKOUT_HANDLER_DECLINE;
    };

You can subclass Handel::Checkout::Message to add your own properties.
If your adding a simple text message, a new Handel::Checkout::Message object
will automatically be created and C<package>, C<filename>, and C<line>
properties will be set.

=head2 add_phase($name, $value [, $import]);

Adds a new constant/sub named $name to Handel::Constant and adds the $value to
CHECKOUT_ALL_PHASES. The new phase will be accepted by &constraint_checkout_phase
and can be used by checkout plugins registering their handlers via
add_handler($phase, &handler). If $import is true, add_phase will register the
constant in the local namespace just as if it you had specified it in your use
statement.

    use Handel::Checkout;

    Handel::Checkout->add_phase('CHECKOUT_PHASE_CUSTOMPHASE', 42, 1);

    print constraint_checkout_phase(&CHECKOUT_PHASE_CUSTOMPHASE);

    $plugincontext->add_handler(Handel::Constants::CHECKOUT_PHASE_CUSTOMPHASE, &handlersub);

=head2 clear_messages

Clears all messages from the current checkout instance.

=head2 cart

Creates a new Handel::Order object from the specified cart and associates
that order with the current checkout process. This is typically only needed
the first time you want to run checkout for a specific cart. From then on,
you only need to load the already created order using C<order> below.

C<cart> can accept one of three possible parameter values:

=over

=item cart(\%filter)

When you pass a HASH reference, C<cart> will attempt to load all available
carts using Handel::Cart::load(\%filter). If multiple carts are found, only
the first one will be used.

    $checkout->cart({
        shopper => '12345678-9098-7654-3212-345678909876',
        type => CART_TYPE_TEMP
    });

=item cart(Handel::Cart)

You can also pass in an already existing Handel::Cart object or subclass. It
will then be loaded into a new order object ans associated with the current
checkout process.

    my $cart = Handel::Cart->load({
        id => '12345678-9098-7654-3212-345678909876'
    });

    $checkout->cart($cart);

=item cart($cartid)

Finally, you can pass a valid cart/uuid into C<cart>. The matching cart
will be loaded into a new Handel::Order object and associated with the
current checkout process.

    $checkout->cart('12345678-9098-7654-3212-345678909876');

=back

=head2 order_class($orderclass)

Gets/Sets the name of the class to use when loading existing order into the
checkout process. By default, it loads order using Handel::Order. While you can
set this directly in your application, it's best to set it in a custom subclass
of Handel::Checkout.

    package CustomCheckout;
    use base 'Handel::Checkout';
    __PACKAGE__->order_class('CustomOrder');

    ...
    use CustomCheckout;
    my $checkout = CustomCheckout->new({order => '11111111-2222-3333-4444-555555555555'});

    print ref $checkout->order; # CustomOrder

=head2 stash_class($stashclass)

Gets/Sets the name of the stash class to create during C<new>. By default, it
returns Handel::Checkout::Stash. While you can
set this directly in your application, it's best to set it in a custom subclass
of Handel::Checkout.

    package CustomCheckout;
    use base 'Handel::Checkout';
    __PACKAGE__->stash_class('MyCustomStash');

=head2 messages

Returns a reference to an array in list context of Handel::Checkout::Message
objects containing additional information about plugin and other checkout
decisions and activities. Returns a list in list context.

    foreach ($checkout->messages) {
        warn $_->text, "\n";
    };

=head2 plugins

Returns a list plugins loaded for checkout instance in list context:

    my $checkout = Handel::Checkout->new;
    my @plugins = $checkout->plugins;

    foreach (@plugins) {
        $_->cleanup_or_something;
    };

Returns an array reference in scalar context.

=head2 order

Gets/Sets an existing Handel::Order object with the existing checkout process.

C<order> can accept one of three possible parameter values:

=over

=item order(\%filter)

When you pass a HASH reference, C<order> will attempt to load all available
order using Handel::Order::load(\%filter). If multiple order are found, only
the first one will be used.

    $checkout->order({
        shopper => '12345678-9098-7654-3212-345678909876',
        id => '11111111-2222-3333-4444-5555666677778888'
    });

=item order(Handel::Order)

You can also pass in an already existing Handel::Order object or subclass. It
will then be associated with the current checkout process.

    my $order = Handel::Order->load({
        id => '12345678-9098-7654-3212-345678909876'
    });

    $checkout->order($order);

=item order($orderid)

Finally, you can pass a valid order/uuid into C<order>. The matching order
will be loaded and associated with the current checkout process.

    $checkout->order('12345678-9098-7654-3212-345678909876');

=back

=head2 phases(\@phases)

Get/Set the phases active for the current checkout process. This can be
an array reference or a comma (or space) separated string:

    $checkout->phases([
        CHECKOUT_PHASE_INITIALIZE,
        CHECKOUT_PHASE_VALIDATION
    ]);

    $checkout->phases('CHECKOUT_PHASE_INITIALIZE, CHECKOUT_PHASE_VALIDATION']);

No attempt is made to sanitize the array for duplicates or the order of the phases.
This means you can do evil things like run a phase twice, or run the phases
out of order. Returns a list in list context and an array reference in scalar context.

=head2 process([\@phases])

Executes the current checkout process pipeline and returns CHECKOUT_STATUS_*.
Any plugin handler that doesn't return CHECKOUT_HANDLER_OK or CHECKOUT_HANDLER_DECLINE
is considered to be an error that the checkout process is aborted.

Just like C<phases>, you can pass an array reference or a comma (or space)
separated string of phases into process.

The method $self->stash->clear is called before the call to
$plugin->setup so plugins can set stash data, and the stash remains until the
next call to process so $plugin->teardown can read any remaining stash data
before C<process> ends.

The call to C<process> will return on of the following constants:

=over

=item CHECKOUT_STATUS_OK

All plugin handlers were called and returned CHECKOUT_HANDLER_OK or CHECKOUT_HANDLER_DECLINE

=item CHECKOUT_STATUS_ERROR

At least one plugin failed to return or an error occurred while processing
the registered plugin handlers.

=back

=head2 stash

Returns a Handel::Checkout::Stash object that can store information shared by
all plugins in the current context.

    # plugin handler
    my ($self, $ctx) = @_;

    $ctx->stash->{'template'} = 'template.tt';

=head1 CONFIGURATION

=head2 HandelPluginPaths

This resets the checkout plugin search path to a namespace of your choosing,
The default plugin search path is Handel::Checkout::Plugin::*

    PerlSetVar HandelPluginPaths MyApp::Plugins

In the example above, the checkout plugin search path will load all plugins
in the MyApp::Plugins::* namespace (but not MyApp::Plugin itself). Any plugins
in Handel::Checkout::Plugin::* will be ignored.

You can also pass a comma or space separate list of namespaces.

    PerlSetVar HandelPluginPaths 'MyApp::Plugins, OtherApp::Plugins'

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head2 HandelAddPluginPaths

This adds an additional plugin search paths. This can be a comma or space
separated list of namespaces.

    PerlSetVar HandelAddPluginPaths  'MyApp::Plugins, OtherApp::Plugins'

In the example above, when a checkout process is loaded, it will load
all plugins in the Handel::Checkout::Plugin::*, MyApp::Plugins::*, and
OtherApp::Plugins namespaces.

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head2 HandelIgnorePlugins

This is a comma/space separated list [or an anonymous array, or a regex outside of httpd.conf] of plugins to ignore when loading
all available plugins in the given namespaces.

    PerlSetVar HandelIgnorePlugins 'Handel::Checkout::Plugin::Initialize'

    $ENV{'HandelIgnorePlugins'} = 'Handel::Checkout::Plugin::Initialize';
    $ENV{'HandelIgnorePlugins'} = ['Handel::Checkout::Plugin::Initialize'];
    $ENV{'HandelIgnorePlugins'} = qr/^Handel::Checkout::Plugin::(Initialize|Validate)$/;

If the Handel::Checkout::Plugin namespace has the following modules:

    Handel::Checkout::Plugin::Initialize
    Handel::Checkout::Plugin::ValidateAddress
    Handel::Checkout::Plugin::FaxDelivery
    Handel::Checkout::Plugin::EmailDelivery

all of the modules above will be loaded <b>except</b> Handel::Checkout::Plugin::Initialize.
All plugins in any other configured namespaces will be loaded.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the plugins in
HandelLoadPlugins will be loaded, unless they are also in HandelIgnorePlugins in which case
they will be ignored.

=head2 HandelLoadPlugins

This is a comma or space separated list [or an anonymous array, or a regex outside of httpd.conf] of plugins to be loaded from the available namespaces.

    PerlSetVar HandelLoadPlugins 'Handel::Checkout::Plugin::ValidateAddress'

    $ENV{'HandelLoadPlugins'} = 'Handel::Checkout::Plugin::ValidateAddress';
    $ENV{'HandelLoadPlugins'} = ['Handel::Checkout::Plugin::ValidateAddress'];
    $ENV{'HandelLoadPlugins'} = qr/^Handel::Checkout::Plugin::(ValidateAddress|Authorize)$/;

If the following plugins are available in all configured namespaces:

    Handel::Checkout::Plugin::Initialize
    Handel::Checkout::Plugin::ValidateAddress
    Handel::Checkout::Plugin::FaxDelivery
    Handel::Checkout::Plugin::EmailDelivery
    MyApp::Plugin::VerifiedByVisa
    MyApp::Plugin::WarehouseUpdate

only Handel::Checkout::Plugin::ValidateAddress will be loaded. All other plugins in all
configured namespaces will be ignored.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the plugins in
HandelLoadPlugins will be loaded, unless they are also in HandelIgnorePlugins in which case
they will be ignored.

=head1 CAVEATS

[I think] Due to the localization of AutoCommit to coerce disabling of autoupdates during process,
Always access orders and order items from their checkout parent once they've been assigned to
the checkout process, and not any available reference:

    my $order = Handel::Order->new({billtofirstname => 'Chris'});
    my $checkout = Handel::Checkout->new({order => $order});

    # some plugin alters billtofirstname to 'Christopher'
    $checkout->process;

    $order->billtofirstname; #Chris
    $checkout->order->billtofirstname; #Christopher

=head1 SEE ALSO

L<Handel::Constants>, L<Handel::Checkout::Plugin>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
