package Template::Plugin::Handel::Cart;
use strict;
use warnings;
use base 'Template::Plugin';
use Handel::Cart;
use Handel::Constants ();

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {_CONTEXT => $context}, ref($class) || $class;

    foreach my $const (@Handel::Constants::EXPORT_OK) {
        $self->{$const} = Handel::Constants->$const;
    };

    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

sub create {
    my ($self, $filter) = @_;

    return Handel::Cart->new($filter);
};

sub fetch {
    my ($self, $filter, $wantiterator) = @_;
    return Handel::Cart->load($filter, $wantiterator);
};

sub guid {
    return shift->uuid;
};

sub uuid {
    return Handel::Cart->uuid;
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Cart - Template Toolkit plugin for shopping cart

=head1 VERSION

    $Id$

=head1 SYNOPSIS

    [% USE Handel.Cart %]
    [% IF (cart = Handel.Cart.fetch(id => 'A2CCD312-73B5-4EE4-B77E-3D027349A055')) %]
        [% cart.name %]
        [% FOREACH item IN cart.items %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::Handel::Cart> is a TT2 (Template Toolkit 2) plugin for
C<Handel::Cart>. It's API is exactly the same as C<Handel::Cart> with a few
minor exceptions noted below.

Since C<new> and C<load> are used by TT2 to load plugins, Handel::Carts
C<new> and C<load> can be accesed using C<create> and C<fetch>.

C<Handel::Constants> are now imported into this module automatically in C<0.08>.

    [% USE hc = Handel.Cart %]
    [% cart = hc.create(...) %]
    [% cart.type(hc.CART_TYPE_TEMP) %]

=head1 CAVEATS

C<Template Toolkit> handles method params in a smart fashion that
allows you to pass named parameters into methoda and it will convert them
into HASH references.

For example:

    [% cart.method(name1=val1, name2=val2, otherarg);

is turned into:

    cart->method(otherarg, {name1=>val1, name2=>val2});

Unfortunatly, it looks like TT2 reverses the @ARGS order during translation.
This causes problems with C<Handel::Cart::load> and C<items> as they expect
C<($hashref, $wantiterator)> instead.

Do to this, it is recommended that you always use the same explicit form as
you would use when calling C<Handel::Cart> when calling C<create> and C<items>:

    [% cart.method({name1=>val1, name2=>val2}, $wantiterator) %]

Other issue is how C<Handel::Cart> returns an iterator or an array based on its
inspection ot C<wantarray>. It appears that TT2 thwarts C<wantarray> in some
manner.

For example:

    [% carts = Handel.Cart.fetch() %]

returns an array reference sinceit's not clear at this point what you really want.
To counteract this behaviour, you can use C<RETURNAS> constants to specify the exact
output desired:

    [% carts = Handel.Cart.fetch(undef, Handel.Cart.RETURNAS_ITERATOR) %]

This will force a return of a C<Handel::Iterator> in scalar context. Then you can
simply loop through the iterator:

    [% WHILE (cart = carts.next) %]
        ...
    [% END %]

On the upshot, if you are only expecting a single result, like loading a specific
cart by C<id>, then it will just do Do What You Want:

    [% cart = Handel.Cart.fetch({id => '12345678-7654-3212-345678987654'}) %]
    [% cart.id %]
    [% cart.name %]
    ...

You can even use C<FOREACH> without specifying the return type as TT2 appears
to just Do The Right Thing regardless of whether it receives an array or a
single C<Handel::Cart> or C<Handel::Cart::Item> object:

    [% FOREACH cart IN Handel.Cart.fetch({id => '12345678-7654-3212-345678987654'}}) %]
        [% FOREACH item IN cart.items %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 CONSTRUCTOR

Unlike using C<Handel::Cart> to create a new cart object using C<new> and
C<load>, C<Template::Plugin::Handel::Cart> takes a slightly different
approach to cart objects. Because C<USE>ing in TT2 calls C<new>, we first
C<USE> or create a new C<Template::Plugin::Handel::Cart> object then
C<create> or C<load> to return a new cart object, iterator, or array of carts.

=over

=item C<create(\%filter)>

    [% USE Handel.Cart %]
    [% IF (cart = Handel.Cart.create({
        shopper => '12345678-9876-5432-1234-567890987654',
        name    => 'My New Cart',
        description =>'Favorite Items'})) %]

        [% cart.name %]
        ...

    [% END %]

=item C<fetch(\%filter [, $wantiterator])>

The safest way to get a cart is to use FOREACH. This negates the need
to specfy C<$wanteriterator> for C<Handel::Cart::load>. See L<CAVEATS>
for further info on C<$wantiterator>, Perls C<wantarray> within TT2.

    [% USE Handel.Cart %]
    [% FOREACH cart IN Handel.Cart.fetch({shopper => '12345678-9876-5432-1234-567890987654'}) %]
        [% cart.id %]
        [% cart.name %]
        ...
    [% END %]

=back

=head1 SEE ALSO

L<Template::Plugin::Handel::Constants>, L<Handel::Constants>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
