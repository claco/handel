# $Id$
package Template::Plugin::Handel::Order;
use strict;
use warnings;
use base 'Template::Plugin';
use Handel::Order;
use Handel::Constants ();

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {_CONTEXT => $context}, $class;

    foreach my $const (@Handel::Constants::EXPORT_OK) {
        if ($const =~ /^[A-Z]{1}/) {
            $self->{$const} = Handel::Constants->$const;
        };
    };
    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

sub create {
    my ($self, $filter) = @_;

    return Handel::Order->new($filter);
};

sub fetch {
    my ($self, $filter, $wantiterator) = @_;
    return Handel::Order->load($filter, $wantiterator);
};

sub guid {
    return shift->uuid;
};

sub uuid {
    return Handel::Order->uuid;
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Order - Template Toolkit plugin for orders

=head1 SYNOPSIS

    [% USE Handel.Order %]
    [% IF (order = Handel.Order.fetch(id => 'A2CCD312-73B5-4EE4-B77E-3D027349A055')) %]
        [% order.number %]
        [% FOREACH item IN order.items %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::Handel::Order> is a TT2 (Template Toolkit 2) plugin for
C<Handel::Order>. It's API is exactly the same as C<Handel::Order> with a few
minor exceptions noted below.

Since C<new> and C<load> are used by TT2 to load plugins, Handel::Orders
C<new> and C<load> can be accesed using C<create> and C<fetch>.

Starting in version C<0.08>, C<Handel::Constants> are now imported into this
module automatically. This removes the need to use
C<Template::Plugin::Handel::Constants> seperately when working with carts.

    [% USE hc = Handel.Order %]
    [% cart = hc.create(...) %]
    [% cart.type(hc.ORDER_TYPE_TEMP) %]

=head1 CAVEATS

C<Template Toolkit> handles method params in a smart fashion that
allows you to pass named parameters into methoda and it will convert them
into HASH references.

For example:

    [% order.method(name1=val1, name2=val2, otherarg);

is turned into:

    order->method(otherarg, {name1=>val1, name2=>val2});

Unfortunatly, it looks like TT2 reverses the @ARGS order during translation.
This causes problems with C<Handel::Order::load> and C<items> as they expect
C<($hashref, $wantiterator)> instead.

Do to this, it is recommended that you always use the same explicit form as
you would use when calling C<Handel::Order> when calling C<create> and C<items>:

    [% order.method({name1=>val1, name2=>val2}, $wantiterator) %]

Other issue is how C<Handel::Order> returns an iterator or an array based on its
inspection ot C<wantarray>. It appears that TT2 thwarts C<wantarray> in some
manner.

For example:

    [% orders = Handel.Order.fetch() %]

returns an array reference since it's not clear at this point what you really
want. To counteract this behaviour, you can use C<RETURNAS> constants to
specify the exact output desired:

    [% orders = Handel.Order.fetch(undef, Handel.Order.RETURNAS_ITERATOR) %]

This will force a return of a C<Handel::Iterator> in scalar context. Then you
can simply loop through the iterator:

    [% WHILE (order = orders.next) %]
        ...
    [% END %]

On the upshot, if you are only expecting a single result, like loading a
specific cart by C<id>, then it will just do Do What You Want:

    [% order = Handel.Order.fetch({id => '12345678-7654-3212-345678987654'}) %]
    [% order.id %]
    [% order.number %]
    ...

You can even use C<FOREACH> without specifying the return type as TT2 appears
to just Do The Right Thing regardless of whether it receives an array or a
single C<Handel::Order> or C<Handel::Order::Item> object:

    [% FOREACH order IN Handel.Order.fetch({id => '12345678-7654-3212-345678987654'}}) %]
        [% FOREACH item IN order.items %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 CONSTRUCTOR

Unlike using C<Handel::Order> to create a new order object using C<new> and
C<load>, C<Template::Plugin::Handel::Order> takes a slightly different
approach to order objects. Because C<USE>ing in TT2 calls C<new>, we first
C<USE> or create a new C<Template::Plugin::Handel::Order> object then
C<create> or C<load> to return a new order object, iterator, or array of carts.

=head2 new

This returns a new Handel.Order object. This is used internally when
loading TT2 plugins and should not be used directly.

=head1 METHODS

=head2 load

This method is called when TT2 loaded the plugin for the first time.
This is used internally by TT2 and should not be used directly.

=head2 create(\%filter)

    [% USE Handel.Order %]
    [% IF (order = Handel.Order.create({
        shopper => '12345678-9876-5432-1234-567890987654',
        number  => 'O123456789'})) %]

        [% cart.number %]
        ...

    [% END %]

=head2 fetch(\%filter [, $wantiterator])

The safest way to get a order is to use FOREACH. This negates the need
to specfy C<$wanteriterator> for C<Handel::Order::load>. See L<CAVEATS>
for further info on C<$wantiterator>, Perls C<wantarray> within TT2.

    [% USE Handel.Order %]
    [% FOREACH order IN Handel.Order.fetch({shopper => '12345678-9876-5432-1234-567890987654'}) %]
        [% order.id %]
        [% order.number %]
        ...
    [% END %]

=head2 uuid

Returns a new uuid for use in add/create:

    [% USE Handel.Order %]
    [% IF (order = Handel.Order.create({
        id      => Handel.Cart.uuid,
        shopper => '12345678-9876-5432-1234-567890987654',
        number  => ')123456789'})) %]

        [% order.number %]
        ...

    [% END %]

=head2 guid

Same as C<uuid> above.

=head1 SEE ALSO

L<Template::Plugin::Handel::Constants>, L<Handel::Constants>, L<Handel::Order>,
L<Template::Plugin>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
