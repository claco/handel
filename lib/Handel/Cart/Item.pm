# $Id: Item.pm 4 2004-12-28 03:01:15Z claco $
package Handel::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constraints qw(:all);
};

__PACKAGE__->table('cart_items');
__PACKAGE__->autoupdate(0);
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns( All => qw(id cart sku quantity price description) );
__PACKAGE__->add_constraint( 'quantity', quantity => \&constraint_quantity );
__PACKAGE__->add_constraint( 'price',    price    => \&constraint_price );
__PACKAGE__->add_constraint( 'id',       id       => \&constraint_uuid );
__PACKAGE__->add_constraint( 'cart',     cart     => \&constraint_uuid );

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
       'Param 1 is not a HASH reference.') unless ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    return $self->construct($data);
};

sub total {
    my $self = shift;
    return $self->quantity * $self->price;
};

1;
__END__

=head1 NAME

Handel::Cart::Item - Cart Item

=head1 METHODS

=over

=item C<new>

=item C<total>

=back

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
