# $Id$
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constants qw/:all/;
    use Handel::Constraints qw/constraint_checkout_phase constraint_uuid/;
    use Handel::Exception qw/try with otherwise finally/;
    use Handel::Checkout::Message;
    use Handel::L10N qw/translate/;
    use Module::Pluggable::Object;
    use Class::Inspector;
    use Scalar::Util qw/blessed/;

    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('component_class', qw/order_class stash_class/);
    __PACKAGE__->mk_group_accessors('simple', qw/stash/);
};

__PACKAGE__->order_class('Handel::Order');
__PACKAGE__->stash_class('Handel::Checkout::Stash');

sub new {
    my $class = shift;
    my $opts = shift || {};
    my $self = bless {
        plugins => [],
        handlers => {},
        phases => [],
        messages => []
    }, $class;

    my $stash = $opts->{'stash'};

    if (blessed $stash) {
        $self->stash($stash);
    } elsif (ref $stash eq 'HASH') {
        $self->stash(
            $self->stash_class->new($stash)
        );
    } else {
        $self->stash(
            $self->stash_class->new
        );
    };

    foreach ($self->load_plugins($opts)) {
        if (blessed($_) && $_->isa('Handel::Checkout::Plugin')) {
            push @{$self->{'plugins'}}, $_;
            $_->register($self);
        };
    };

    if ($opts->{'cart'}) {
        $self->cart($opts->{'cart'});
    };
    if ($opts->{'order'}) {
        $self->order($opts->{'order'});
    };
    if ($opts->{'phases'}) {
        $self->phases($opts->{'phases'});
    };

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
        translate('PARAM1_NOT_CHECKOUT_PHASE')
    ) unless constraint_checkout_phase($phase); ## no critic

    throw Handel::Exception::Argument( -details =>
        translate('PARAM1_NOT_CODEREF')
    ) unless ref($ref) eq 'CODE'; ## no critic

    foreach (@{$self->{'plugins'}}) {
        if (ref $_ eq $package) {
            if ($preference) {
                if (exists $self->{'handlers'}->{$phase}->{$preference}) {
                    my $plugin = $self->{'handlers'}->{$phase}->{$preference}->[0];

                    throw Handel::Exception::Checkout( -details =>
                        translate('HANDLER_EXISTS_IN_PHASE', $phase, $preference, $plugin)
                    );
                };
            } else {
                my @prefs = sort {$a <=> $b} keys %{$self->{'handlers'}->{$phase}};
                $preference = scalar @prefs ? $#prefs++ : 101;
            };
            $self->{'handlers'}->{$phase}->{$preference} = [$_, $ref];
            last;
        };
    };

    return;
};

sub add_message {
    my ($self, $message) = @_;
    my ($package, $filename, $line) = caller;

    if (blessed($message) && $message->isa('Handel::Checkout::Message')) {
        $message->package($package) unless $message->package;       ## no critic
        $message->filename($filename) unless $message->filename;    ## no critic
        $message->line($line) unless $message->line;                ## no critic

        push @{$self->{'messages'}}, $message;
    } elsif (!ref $message || ref $message eq 'Apache::AxKit::Exception::Error') {
        push @{$self->{'messages'}}, Handel::Checkout::Message->new(
            text => $message, source => $package, filename => $filename, line => $line);
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('PARAM1_NOT_CHECKOUT_MESSAGE')
        );
    };

    return;
};

sub add_phase {
    my ($self, $name, $value, $import) = @_;
    my $caller = (caller);

    if (Handel::Constants->can($name)) {
        throw Handel::Exception::Constraint(
            -text => translate('CONSTANT_NAME_ALREADY_EXISTS', $name)
        );
    } elsif (constraint_checkout_phase($value)) {
        throw Handel::Exception::Constraint(
            -text => translate('CONSTANT_VALUE_ALREADY_EXISTS', $value)
        );
    } elsif ($import && main->can($name)) {
        throw Handel::Exception::Constraint(
            -text => translate('CONSTANT_EXISTS_IN_CALLER', $name, $caller)
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

    return;
};

sub clear_messages {
    my $self = shift;

    $self->{'messages'} = [];

    return;
};

sub cart {
    my ($self, $cart) = @_;

    if ($cart) {
        $self->order($self->order_class->create({cart => $cart}));
    };

    return;
};

sub messages {
    my $self = shift;

    return wantarray ? @{$self->{'messages'}} : $self->{'messages'};
};

sub order {
    my ($self, $order) = @_;

    if ($order) {
        if (ref $order eq 'HASH') {
            $self->{'order'} = $self->order_class->search($order)->first;
        } elsif (blessed($order) && $order->isa('Handel::Order')) {
            $self->{'order'} = $order;
        } elsif (!ref $order) {
            my ($primary_key) = $self->order_class->storage->primary_columns;

            $self->{'order'} = $self->order_class->search({$primary_key => $order})->first;
        } else {
            throw Handel::Exception::Argument( -details =>
                translate('PARAM1_NOT_HASHREF_ORDER')
            );
        };

        if (!$self->order) {
            throw Handel::Exception::Checkout( -details =>
                translate('ORDER_NOT_FOUND')
            );
        };
    };

    return $self->{'order'};
};

sub phases {
    my ($self, $phases) = @_;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate('PARAM1_NOT_ARRAYREF_STRING')
        ) unless (ref($phases) eq 'ARRAY' || !ref($phases)); ## no critic

        if (! ref $phases) {
            # holy crap, that actually worked!
            $phases = [map(eval "$_", _path_to_array($phases))];
        };

        $self->{'phases'} = [map {eval "$_"} @{$phases}];
    } else {
        if (wantarray) {
            return (scalar @{$self->{'phases'}}) ? @{$self->{'phases'}} : @{&CHECKOUT_DEFAULT_PHASES}; ## no critic
        } else {
            return (scalar @{$self->{'phases'}}) ? $self->{'phases'} : CHECKOUT_DEFAULT_PHASES;
        };
    };

    return;
};

sub process {
    my $self = shift;
    my $phases = shift;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate('PARAM1_NOT_ARRAYREF_STRING')
        ) unless (ref($phases) eq 'ARRAY' || ! ref($phases)); ## no critic

        if (! ref $phases) {
            # holy crap, that actually worked!
            $phases = [map(eval "$_", _path_to_array($phases))];
        };
    } else {
        $phases = scalar @{$self->{'phases'}} ? $self->{'phases'} : CHECKOUT_DEFAULT_PHASES;
    };

    throw Handel::Exception::Checkout( -details =>
        translate('NO_ORDER_LOADED')
    ) unless $self->order; ## no critic

    $self->_setup;

    {
        $self->order->result->txn_begin;

        foreach my $phase (@{$phases}) {
            next unless $phase;

            my @handlerprefs = sort {$a <=> $b} keys %{$self->{'handlers'}->{$phase}};
            foreach my $handlerpref (@handlerprefs) {
                my $handler = $self->{'handlers'}->{$phase}->{$handlerpref};
                my $status = $handler->[1]->($handler->[0], $self);

                if ($status != CHECKOUT_HANDLER_OK && $status != CHECKOUT_HANDLER_DECLINE) {
                    $self->_teardown($self);

                    try {
                        $self->order->result->txn_rollback;
                        $self->order->result->discard_changes;
                        foreach my $item ($self->order->items->all) {
                            $item->result->discard_changes;
                        };
                    } otherwise {
                        throw Handel::Exception::Checkout(-details => translate('ROLLBACK_FAILED', shift));
                    };

                    return CHECKOUT_STATUS_ERROR;
                };
            };
        };

        $self->order->result->txn_commit;
    };

    $self->_teardown;

    return CHECKOUT_STATUS_OK;
};

sub _setup {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->setup($self);
        };
    };

    return;
};

sub _teardown {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->teardown($self);
        };
    };

    return;
};

sub load_plugins {
    my ($self, $opts) = @_;
    my ($package, $file) = caller;
    my $config = Handel->config;
    my $search_path;

    my $pluginpaths = ref $opts->{'pluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'pluginpaths'}}) : $opts->{'pluginpaths'} || '';

    my $addpluginpaths = ref $opts->{'addpluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'addpluginpaths'}}) : $opts->{'addpluginpaths'} || '' ;

    if ($pluginpaths) {
        $search_path = [_path_to_array($pluginpaths)];
    } elsif (my $path = $config->{'HandelPluginPaths'}) {
        $search_path = [_path_to_array($path)];
    } elsif ($path = $config->{'HandelAddPluginPaths'} || $addpluginpaths) {
        $search_path = ["$package\:\:Plugin", _path_to_array("$path $addpluginpaths")];
    } else {
        $search_path = ["$package\:\:Plugin"];
    };

    my $ignore = $opts->{'ignoreplugins'} || $config->{'HandelIgnorePlugins'};
    if (ref $ignore ne 'Regexp' && ref $ignore ne 'ARRAY' && $ignore) {
        $ignore = [_path_to_array($ignore)];
    };

    my $only = $opts->{'loadplugins'} || $config->{'HandelLoadPlugins'};
    if (ref $only ne 'Regexp' && ref $only ne 'ARRAY' && $only) {
        $only = [_path_to_array($only)];
    };

    my $finder = Module::Pluggable::Object->new(
        instantiate => 'new',
        package     => $package,
        file        => $file,
        search_path => $search_path,
        except      => $ignore,
        only        => $only
    );

    return $finder->plugins;
};

sub _path_to_array {
    my $path = shift or return '';

    # ditch begin/end space, replace comma with space and
    # split on space
    $path =~ s/(^\s+|\s+$)//;
    $path =~ s/,/ /g;

    return split /\s+/, $path;
};

sub get_component_class {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "require $value"; ## no critic
    
            throw Handel::Exception::Checkout(
                -details => translate('COMPCLASS_NOT_LOADED', $field, $value)
            ) if $@; ## no critic
        };
    };

    $self->set_inherited($field, $value);

    return;
};

1;
__END__

=head1 NAME

Handel::Checkout - Checkout Pipeline Processor

=head1 SYNOPSIS

    use Handel::Checkout;
    use strict;
    use warnings;
    
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

=head2 new

=over

=item Arguments: \%options

=back

Creates a new checkout pipeline process and loads all available plugins in the
default plugin namespace (Handel::Checkout::Plugin). C<new> accepts the
following options in an optional HASH reference:

=over

=item cart

A HASH reference, a class object, or a cart primary key value. This will be
loaded into a new order object and associated with the new checkout
process. By default, a Handel::Order object will be create unless you have
set C<order_class> to another class.

See C<cart> below for further details about the various values allowed
to be passed.

B<Note>: When creating a new order via Handel::Order, C<new> will automatically
create a checkout process and process the C<CHECKOUT_PHASE_INITIALIZE> phase.
However, when a new order is created using C<cart> in Handel::Checkout, the
automatic processing of C<CHECKOUT_PHASE_INITIALIZE> is disabled.

=item order

A HASH reference, an order object, or an order primary key value. This will be
loaded and associated with the new checkout process. By default, a Handel::Order
object will be create when you pass in an order id unless you have set
C<order_class> to another class.

See C<order> below for further details about the various values allowed
to be passed.

=item pluginpaths

An array reference or a comma (or space) separated list containing the various
namespaces of plugins to be loaded. This will override any settings in
C<ENV> or F<httpd.conf> for the current checkout object only.

    my $checkout = Handel::Checkout->new({
        pluginpaths => [MyNamespace::Plugins, Other::Plugin]
    });
    
    my $checkout = Handel::Checkout->new({
        pluginpaths => 'MyNamespace::Plugins, Other::Plugin'
    });

See L</HandelPluginPaths> for more information about settings/resetting
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

See L</HandelAddPluginPaths> for more information about settings/resetting
plugin search paths.

=item loadplugins

An array reference or a comma (or space) separated list containing the
names of the specific plugins to load in the current plugin paths.

See L</HandelLoadPlugins> for more information about loading specific
plugins.

=item ignoreplugins

An array reference or a comma (or space) separated list containing the
names of the specific plugins to be ignored (not loaded)
in the current plugin paths.

See L</HandelIgnorePlugins> for more information about ignore specific
plugins.

=item phases

An array reference or a comma (or space) separated list containing the
various phases to be executed.

    my $checkout = Handel::Checkout->new({
        phases => [CHECKOUT_PHASE_VALIDATE,
                   CHECKOUT_PHASE_AUTHORIZE]
    });
    
    my $checkout = Handel::Checkout->new({
        phases => 'CHECKOUT_PHASE_VALIDATE, CHECKOUT_PHASE_AUTHORIZE'
    });

=item stash

A Handel::Checkout::Stash object, subclass or a hash reference. If nothing is
specified, C<stash_class> will be used instead.

    my $checkout = Handel::Checkout->new({
        stash => { key => 'value' }
    });
    
    my $checkout = Handel::Checkout->new({
        stash => $stash
    });

=back

=head1 METHODS

=head2 add_handler

=over

=item Arguments: $phase, \&coderef, $preference

=back

Registers a code reference with the checkout phase specified and assigns a run
order preference. This is usually called within C<register> on the current
checkout context within a plugin:

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

While not enforced, please keep your handler preference orders between
251 - 749. Preference orders 1-250 and 750-1000 will be reserved for core
modules that need to run before or after all other plugin handlers.

=head2 add_message

=over

=item Arguments: $message

=back

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

=head2 add_phase

=over

=item Arguments: $name, $value [, $import]

=back

Adds a new constant/sub named $name to Handel::Constant and adds the $value to
CHECKOUT_ALL_PHASES. The new phase will be accepted by
C<constraint_checkout_phase> and can be used by checkout plugins registering
their handlers via add_handler($phase, &handler). If $import is true,
C<add_phase> will register the constant in the local namespace just as if it
you had specified it in your use statement.

    use Handel::Checkout;
    
    Handel::Checkout->add_phase('CHECKOUT_PHASE_CUSTOMPHASE', 42, 1);
    
    print constraint_checkout_phase(&CHECKOUT_PHASE_CUSTOMPHASE);
    
    $plugincontext->add_handler(
        Handel::Constants::CHECKOUT_PHASE_CUSTOMPHASE, &handlersub
    );

=head2 clear_messages

Clears all messages from the current checkout object.

=head2 cart

Creates a new order object from the specified cart and associates
that order with the current checkout process. This is typically only needed
the first time you want to run checkout for a specific cart. From then on,
you only need to load the already created order using C<order> below.

By default, a Handel::Order object will be create unless you have
set C<order_class> to another class. When the order class loads a cart by id, it
will create a cart using the C<cart_class> set in the C<order_class>.

C<cart> can accept one of three possible parameter values:

=over

=item cart(\%filter)

When you pass a HASH reference, C<cart> will attempt to load all available
carts. If multiple carts are found, only the first one will be used.

    $checkout->cart({
        shopper => '12345678-9098-7654-3212-345678909876',
        type => CART_TYPE_TEMP
    });

=item cart($cart)

You can also pass in an already existing Handel::Cart object or subclass. It
will then be loaded into a new order object and associated with the current
checkout process.

    my $cart = Handel::Cart->search({
        id => '12345678-9098-7654-3212-345678909876'
    })->first;
    
    $checkout->cart($cart);

=item cart('11111111-1111-1111-1111-111111111111')

Finally, you can pass a valid cart/uuid into C<cart>. The matching cart will be
loaded into a new order object and associated with the current checkout
process.

    $checkout->cart('12345678-9098-7654-3212-345678909876');

=back

=head2 order_class

=over

=item Arguments: $order_class

=back

Gets/sets the name of the class to use when loading an existing order into the
checkout process or when creating a new order from an existing cart. By default,
it loads order using Handel::Order. While you can set this directly in your
application, it's best to set it in a custom subclass of Handel::Checkout.

    package CustomCheckout;
    use strict;
    use warnings;
    use base qw/Handel::Checkout/;
    __PACKAGE__->order_class('CustomOrder');
    
    ...
    use CustomCheckout;
    my $checkout = CustomCheckout->new({
        order => '11111111-2222-3333-4444-555555555555'
    });
    
    print ref $checkout->order; # CustomOrder

=head2 stash_class

=over

=item Arguments: $stash_class

=back

Gets/sets the name of the stash class to create during C<new>. By default, it
returns Handel::Checkout::Stash. While you can set this directly in your
application, it's best to set it in a custom subclass of Handel::Checkout.

    package CustomCheckout;
    use strict;
    use warnings;
    use base qw/Handel::Checkout/;
    __PACKAGE__->stash_class('MyCustomStash');

=head2 messages

Returns a reference to an array in scalar context of Handel::Checkout::Message
objects containing additional information about plugin and other checkout
decisions and activities. Returns a list in list context.

    foreach ($checkout->messages) {
        warn $_->text, "\n";
    };

=head2 load_plugins

=over

=item Arguments: \%options

=back

Returns a list of plugins pre-instantiated that match the options specified.
The plugins returned are not yet registered.

See L</new> for the available plugin/plugin path options.

=head2 plugins

Returns a list plugins loaded for current checkout object in list context:

    my $checkout = Handel::Checkout->new;
    my @plugins = $checkout->plugins;
    
    foreach (@plugins) {
        $_->cleanup_or_something;
    };

Returns an array reference in scalar context.

=head2 order

Gets/sets an existing order object with the existing checkout process. By
default, a Handel::Order object will be create unless you have set
C<order_class> to another class.

C<order> can accept one of three possible parameter values:

=over

=item order(\%filter)

When you pass a HASH reference, C<order> will attempt to load all available
orders. If multiple order are found, only the first one will be used.

    $checkout->order({
        shopper => '12345678-9098-7654-3212-345678909876',
        id => '11111111-2222-3333-4444-5555666677778888'
    });

=item order($order)

You can also pass in an already existing Handel::Order object or subclass. It
will then be associated with the current checkout process.

    my $order = Handel::Order->search({
        id => '12345678-9098-7654-3212-345678909876'
    })->first;
    
    $checkout->order($order);

=item order('11111111-1111-1111-1111-111111111111')

Finally, you can pass a valid order/uuid into C<order>. The matching order
will be loaded and associated with the current checkout process.

    $checkout->order('12345678-9098-7654-3212-345678909876');

=back

=head2 phases

=over

=item Arguments: \@phases

=back

Gets/sets the phases active for the current checkout process. This can be
an array reference or a comma (or space) separated string:

    $checkout->phases([
        CHECKOUT_PHASE_INITIALIZE,
        CHECKOUT_PHASE_VALIDATE
    ]);
    
    $checkout->phases('CHECKOUT_PHASE_INITIALIZE, CHECKOUT_PHASE_VALIDATE']);

No attempt is made to sanitize the array for duplicates or the order of the
phases. This means you can do evil things like run a phase twice, or run the
phases out of order. Returns a list in list context and an array reference in
scalar context.

=head2 process

=over

=item Arguments: \@phases

=back

Executes the current checkout process pipeline and returns CHECKOUT_STATUS_*.
Any plugin handler that doesn't return CHECKOUT_HANDLER_OK or
CHECKOUT_HANDLER_DECLINE is considered to be an error that the checkout process
is aborted.

Just like C<phases>, you can pass an array reference or a comma (or space)
separated string of phases into process.

The C<clear> method is called on the stash before the call to C<setup> on each
plugin so plugins can set stash data, and the stash remains until the next call
to process so $plugin->teardown can read any remaining stash data
before C<process> ends.

The call to C<process> will return one of the following constants:

=over

=item C<CHECKOUT_STATUS_OK>

All plugin handlers were called and returned CHECKOUT_HANDLER_OK or
CHECKOUT_HANDLER_DECLINE

=item C<CHECKOUT_STATUS_ERROR>

At least one plugin failed to return or an error occurred while processing
the registered plugin handlers.

=back

=head2 stash

Returns a stash object that can store information shared by all plugins in the
current context. By default, a Handel::Checkout::Stash object will be create
unless you have set C<stash_class> to another class.

    # plugin handler
    my ($self, $ctx) = @_;

    $ctx->stash->{'template'} = 'template.tt';

=head2 get_component_class

=over

=item Arguments: $name

=back

Gets the current class for the specified component name.

    my $class = $self->get_component_class('cart_class');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_class

=over

=item Arguments: $name, $value

=back

Sets the current class for the specified component name.

    $self->set_component_class('cart_class', 'MyCartClass');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

There is no good reason to use this. Use the specific class accessors instead.

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

Any plugin found in the search path that isn't a subclass of
Handel::Checkout::Plugin will be ignored.

=head2 HandelAddPluginPaths

This adds an additional plugin search paths. This can be a comma or space
separated list of namespaces.

    PerlSetVar HandelAddPluginPaths  'MyApp::Plugins, OtherApp::Plugins'

In the example above, when a checkout process is loaded, it will load
all plugins in the Handel::Checkout::Plugin::*, MyApp::Plugins::*, and
OtherApp::Plugins namespaces.

Any plugin found in the search path that isn't a subclass of
Handel::Checkout::Plugin will be ignored.

=head2 HandelIgnorePlugins

This is a comma/space separated list [or an anonymous array, or a regex outside
of httpd.conf] of plugins to ignore when loading all available plugins in the
given namespaces.

    PerlSetVar HandelIgnorePlugins 'Handel::Checkout::Plugin::Initialize'

    $ENV{'HandelIgnorePlugins'} = 'Handel::Checkout::Plugin::Initialize';
    $ENV{'HandelIgnorePlugins'} = ['Handel::Checkout::Plugin::Initialize'];
    $ENV{'HandelIgnorePlugins'} = qr/^Handel::Checkout::Plugin::(Initialize|Validate)$/;

If the Handel::Checkout::Plugin namespace has the following modules:

    Handel::Checkout::Plugin::Initialize
    Handel::Checkout::Plugin::ValidateAddress
    Handel::Checkout::Plugin::FaxDelivery
    Handel::Checkout::Plugin::EmailDelivery

all of the modules above will be loaded <b>except</b>
Handel::Checkout::Plugin::Initialize. All plugins in any other configured
namespaces will be loaded.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the
plugins in HandelLoadPlugins will be loaded, unless they are also in
HandelIgnorePlugins in which case they will be ignored.

=head2 HandelLoadPlugins

This is a comma or space separated list [or an anonymous array, or a regex
outside of httpd.conf] of plugins to be loaded from the available namespaces.

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

only Handel::Checkout::Plugin::ValidateAddress will be loaded. All other
plugins in all configured namespaces will be ignored.

If both HandelLoadPlugins and HandelIgnorePlugins are specified, only the
plugins in HandelLoadPlugins will be loaded, unless they are also in
HandelIgnorePlugins in which case they will be ignored.

=head1 CAVEATS

[I think] Due to the localization of AutoCommit to coerce disabling of
autoupdates during process, Always access orders and order items from their
checkout parent once they've been assigned to
the checkout process, and not any available reference:

    my $order = Handel::Order->create({billtofirstname => 'Chris'});
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
