# $Id: Cart.pm 4 2004-12-28 03:01:15Z claco $
package Handel::Cart;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constants qw(:cart);
    use Handel::Constraints qw(:all);
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->table('cart');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id shopper type name description));
__PACKAGE__->has_many(_items => 'Handel::Cart::Item', 'cart');
__PACKAGE__->add_constraint('id',      id      => \&constraint_uuid);
__PACKAGE__->add_constraint('shopper', shopper => \&constraint_uuid);
__PACKAGE__->add_constraint('type',    type    => \&constraint_cart_type);

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference.') unless ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    if (!defined($data->{'type'})) {
        $data->{'type'} = CART_TYPE_TEMP;
    };

    return $self->create($data);
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference or Handel::Cart::Item.') unless(
            ref($data) eq 'HASH' or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
            $data->{'id'} = $self->uuid;
        };

        return $self->add_to__items($data);
    } else {
        my %copy = %{$data};

        $copy{'id'} = $self->uuid;

        return $self->add_to__items(\%copy);
    };
};

sub clear {
    my $self = shift;

    $self->_items->delete_all;

    return undef;
};

sub count {
    my $self  = shift;

    return $self->_items->count || 0;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference.') unless ref($filter) eq 'HASH';

    ## I'd much rather use $self->_items->search_like, but it doesn't work that
    ## way yet. This should be fine as long as :weaken refs works.
    return Handel::Cart::Item->search_like(%{$filter},
        cart => $self->id)->delete_all;
};

sub items {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter ||= {};

    my $wildcard = Handel::DBI::has_wildcard($filter);

    ## If the filter as a wildcard, push it through a fresh search_like since it
    ## doesn't appear to be available witin a loaded object.
    if (wantarray) {
        my @items = $wildcard ?
            Handel::Cart::Item->search_like(%{$filter}, cart => $self->id) :
            $self->_items(%{$filter});

        return @items;
    } else {
        my $iterator = $wildcard ?
            Handel::Cart::Item->search_like(%{$filter}, cart => $self->id) :
            $self->_items(%{$filter});
        if ($iterator->count == 1 and !$wantiterator) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub load {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference.') unless(
            ref($filter) eq 'HASH' or !$filter);

    if (wantarray) {
        my @carts = $filter ? $self->search_like(%{$filter}) :
            $self->retrieve_all;
        return @carts;
    } else {
        my $iterator = $filter ?
            $self->search_like(%{$filter}) : $self->retrieve_all;

        if ($iterator->count == 1 && !$wantiterator) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub restore {
    my ($self, $data, $mode) = @_;

    $mode ||= CART_MODE_REPLACE;

    throw Handel::Exception::Argument( -details =>
        'Param 1 is not a HASH reference or Handel::Cart.') unless(
            ref($data) eq 'HASH' or $data->isa('Handel::Cart'));

    if (ref($data) eq 'HASH') {

    };

    if ($mode == CART_MODE_REPLACE) {
        $self->clear;

        $self->autoupdate(0);
        $self->name($data->name);
        $self->description($data->description);
        $self->update;
        $self->autoupdate(1);

        my $iterator = $data->items(undef, 1);
        while (my $item = $iterator->next) {
            $self->add($item);
        };
    } elsif ($mode == CART_MODE_MERGE) {

    } elsif ($mode == CART_MODE_APPEND) {
        my $iterator = $data->items(undef, 1);
        while (my $item = $iterator->next) {
            $self->add($item);
        };
    } else {
        return new Handel::Exception::Argument(-text => 'Unknown restore mode');
    };
};

sub save {
    $_[0]->type(CART_TYPE_SAVED);

    return undef;
};

sub subtotal {
    my $self     = shift;
    my $it       = $self->items(undef, 1);
    my $subtotal = 0.00;

    while ( my $item = $it->next ) {
        $subtotal += ( $item->total );
    };

    return $subtotal;
};

1;
__END__

=head1 NAME

Handel::Cart - Shopping Cart

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/

=head1 METHODS

=over

=item C<new>

=item C<add>

=item C<clear>

=item C<count>

=item C<delete>

=item C<items>

=item C<load>

=item C<restore>

=item C<save>

=item C<subtotal>

=back





