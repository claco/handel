# $Id$
package Catalyst::Model::Handel::Cart;
use strict;
use warnings;

BEGIN {
    use base qw/Catalyst::Model Class::Accessor::Grouped/;
    use Class::Inspector;
    use Catalyst::Exception;
    use Handel::L10N qw/translate/;
};

__PACKAGE__->mk_group_accessors('inherited', qw/cart_manager/);

sub COMPONENT {
    my $self = shift->SUPER::new(@_);
    my $cart_class = $self->{'cart_class'} || 'Handel::Cart';

    if (!Class::Inspector->loaded($cart_class)) {
        eval "use $cart_class"; ## no critic;
        if ($@) {
            Catalyst::Exception->throw(
                message => translate('Could not load cart class [_1]: [_2]', $cart_class, $@)
            );
        };
    };

    my $manager = bless {
        storage => $cart_class->storage->clone
    }, $cart_class;

    foreach my $key (keys %{$self}) {
        if ($manager->storage->can($key)) {
            $manager->storage->$key($self->{$key});
        };
    };

    $self->cart_manager($manager);

    return $self;
};

sub new {
    return shift->cart_manager->new(@_);
};

sub AUTOLOAD {
    my ($method) = (our $AUTOLOAD =~ /([^:]+)$/);

    return if $method =~ /(DESTROY|ACCEPT_CONTEXT)/;

    return shift->cart_manager->$method(@_);
};

1;
__END__

=head1 NAME

Catalyst::Model::Handel::Cart - Base class for Handel cart classes

=head1 SYNOPSIS

    package MyApp::Model::Cart;
    use strict;
    use warnings;
    
    BEGIN {
        use base qw/Catalyst::Model::Handel::Cart/;
    };
    
    __PACKAGE__->config(
        connection_info => ['dbi:mysql:localhost', 'user', 'pass']
    );
    
    # in your cat constrollers
    my $cart = $c->model('Cart')->create({
        name => 'My Cart'
    });

=head1 DESCRIPTION

Catalyst::Model::Handel::Cart is the base class for all Handel cart related
models in a Catalyst application. It takes care of loading the specified cart
class and configuring it based on any configuration options set in the model
class or application config file.

=head1 CONFIGURATION

You can configure your model in one of two ways. First, you can set options
within your model class itself:

    package MyApp::Model::Cart;
    use strict;
    use warnings;
    
    BEGIN {
        use base qw/Catalyst::Model::Handel::Cart/;
    };
    
    __PACKAGE__->config(
        connection_info => ['dbi:mysql:localhost', 'user', 'pass']
    );

You can also specify configuration on your application config file:

    Model::Cart:
      connection_info:
        - dbi:mysql:localhost
        - user
        - pass

All connection options are passed into the current cart classes storage object.
See L<Handel::Storage> and L<Handel::Storage::DBIC> for the available
configuration options.

If no cart_class is specified, Handel::Cart will be used by default.

=head1 METHODS

Once loaded, all method requests to this model are forwarded to the specified
cart class.

=head2 COMPONENT

See L<Catalyst::Component> for more information.

=head2 new

This is a placeholder to forward calls to C<new> to the cart manager (should it
actually have it's own new method) rather than exposing C<new> from
Catalyst::Component.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Storage>, L<Handel::Storage::DBIC>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
