# $Id$
package Template::Plugin::Handel::Checkout;
use strict;
use warnings;
use base 'Template::Plugin';
use Handel::Checkout;
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

    return Handel::Checkout->new($filter);
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Checkout - Template Toolkit plugin for checkout processing

=head1 SYNOPSIS

    [% USE Handel.Checkout %]
    [% IF (checkout = Handel.Checkout.create(order => 'A2CCD312-73B5-4EE4-B77E-3D027349A055')) %]
        [% checkout.process %]
        [% FOREACH message IN checkout.messages %]
            [% message.text %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::Handel::Checkout> is a TT2 (Template Toolkit 2) plugin for
C<Handel::Checkout>. It's API is exactly the same as C<Handel::Checkout> with a few
minor exceptions noted below.

Since C<new> is used by TT2 to load plugins, Handel::Checkouts
C<new> can be accessed using C<create>.

Starting in version C<0.08>, C<Handel::Constants> are now imported into this
module automatically. This removes the need to use
C<Template::Plugin::Handel::Constants> separately when working with carts.

    [% USE hc = Handel.Constants %]
    [% cart = hc.create(...) %]
    [% cart.type(hc.CHECKOUT_PHASE_INITIALIZE) %]

=head1 CAVEATS

C<Template Toolkit> handles method params in a smart fashion that
allows you to pass named parameters into methods and it will convert them
into HASH references.

For example:

    [% checkout.method(name1=val1, name2=val2, otherarg);

is turned into:

    checkout->method(otherarg, {name1=>val1, name2=>val2});

Unfortunately, it looks like TT2 reverses the @ARGS order during translation.
This causes problems with C<Handel::Order::load> and C<items> as they expect
C<($hashref, $wantiterator)> instead.

Do to this, it is recommended that you always use the same explicit form as
you would use when calling C<Handel::Checkout> when calling C<create> and C<items>:

    [% checkout.method({name1=>val1, name2=>val2}, $wantiterator) %]


=head1 CONSTRUCTOR

Unlike using C<Handel::Checkout> to create a new checkout object using C<new>,
C<Template::Plugin::Handel::Checkout> takes a slightly different
approach to checkout objects. Because C<USE>ing in TT2 calls C<new>, we first
C<USE> or create a new C<Template::Plugin::Handel::Checkout> object then
C<create> to return a new checkout object.

=head2 new

This returns a new Handel.Checkout object. This is used internally when
loading TT2 plugins and should not be used directly.

=head1 METHODS

=head2 create(\%options)

    [% USE Handel.Checkout %]
    [% IF (checkout = Handel.Checkout.create({
        order => '12345678-9876-5432-1234-567890987654'})) %]

        [% order.process %]
        ...

    [% END %]

=head1 SEE ALSO

L<Template::Plugin::Handel::Constants>, L<Handel::Constants>, L<Handel::Checkout>,
L<Template::Plugin>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
