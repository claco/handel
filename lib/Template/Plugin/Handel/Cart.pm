# $Id$
package Template::Plugin::Handel::Cart;
use strict;
use warnings;
use base 'Template::Plugin';
use Handel::Cart;
use vars qw($AUTOLOAD);

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {
        _CONTEXT => $context,
        _cart    => undef
    }, ref($class) || $class;

    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

sub add {
    my ($self, $filter) = @_;

    return $self->{_cart}->add($filter);
};

sub count {
    return shift->{_cart}->count;
};

sub clear {
    shift->{_cart}->clear;
};

sub create {
    my ($self, $filter) = @_;

    $self->{_cart} = Handel::Cart->new($filter);

    return $self->{_cart};
};

sub delete {
    my ($self, $filter) = @_;

    $self->{_cart}->delete($filter);
};

sub description {
    return shift->{_cart}->description;
};

sub fetch {
    my ($self, $filter, $wantiterator) = @_;

    if (ref($wantiterator) eq 'HASH' && ref($filter) ne 'HASH') {
        ($filter, $wantiterator) = ($wantiterator, $filter);
    };

    $self->{_cart} = Handel::Cart->load($filter, $wantiterator);

    return $self->{_cart};
};

sub guid {
    return Handel::Cart->uuid;
};

sub items {
    my ($self, $filter, $wantiterator) = @_;

    if (ref($wantiterator) eq 'HASH' && ref($filter) ne 'HASH') {
        ($filter, $wantiterator) = ($wantiterator, $filter);
    };

    $self->{_cart}->items($filter, $wantiterator);
};

sub name {
    return shift->{_cart}->name;
};

sub restore {
    my ($self, $search, $mode) = @_;

    if (ref($mode) eq 'HASH' && ref($search) ne 'HASH') {
        ($search, $mode) = ($mode, $search);
    };

    $self->{_cart}->restore($search, $mode);
};

sub save {
    shift->{_cart}->save;
};

sub subtotal {
    return shift->{_cart}->subtotal;
};

sub type {
    return shift->{_cart}->type;
};

sub uuid {
    return Handel::Cart->uuid;
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Cart - Template Toolkit plugin for shopping cart

=head2 SYNOPSIS

    [% USE cart = Handel.Cart %]
    [% IF cart.fetch(id='11111111-1111-1111-1111-111111111111') %]
        [% FOREACH item = cart.items %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

C<Template::Plugin::Handel::Cart> is a TT2 (Template Toolkit 2) plugin for
C<Handel::Cart>. It's API is exactly the same as C<Handel::Cart> with a few
minor exceptions.

Since C<new> and C<load> are used by TT2 to load plugins, Handel::Carts
C<new> and C<load> can be accesed using C<create> and C<fetch>.

=head1 CONSTRUCTOR

=over

=item C<create>

=item C<fetch>

=back

=head1 METHODS

=head2 Adding Cart Items

=over

=item C<add>

=back

=head2 Fetching Cart Items

=over

=item C<items>

=back

=head2 Removing Cart Items

=over

=item C<clear>

=item C<delete>

=back

=head2 Saving Cart Items

=over

=item C<save>

=back

=head2 Restoring A Previously Saved Cart

=over

=item C<restore>

=back

=head2 Misc. Methods

=over

=item C<count>

=item C<description>

=item C<name>

=item C<subtotal>

=item C<type>

=item C<uuid>

=item C<guid>

=back

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
