# $Id$
package Handel::Schema::DBIC::Cart;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class/;
};

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('cart');
__PACKAGE__->source_name('Carts');
__PACKAGE__->add_columns(
    id => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },
    shopper => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },
    type => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 0
    },
    name => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => undef
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(items => 'Handel::Schema::DBIC::Cart::Item', {'foreign.cart' => 'self.id'});

1;
__END__

=head1 NAME

Handel::Schema::DBIC::Cart - DBIC schema class for the cart table

=head1 SYNOPSIS

    use Handel::Cart::Schema;
    use strict;
    use warnings;
    
    my $schema = Handel::Cart::Schema->connect;
    
    my $cart = $schema->resultset("Carts")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::DBIC::Cart is loaded by Handel::Cart::Schema to read/write data
to the cart table.

=head1 COLUMNS

=head2 id

Contains the primary key for each cart record. By default, this is a uuid
string.

    id => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },

=head2 shopper

Contains the keys used to tie each cart to a specific shopper. By default, this
is a uuid string.

    shopper => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },

=head2 type

Contains the type for this shopping cart. The current values are
C<CART_TYPE_TEMP> and C<CART_TYPE_SAVED> from
L<Handel::Constants|Handel::Constants>.

    type => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 0
    },

=head2 name

Contains the name of the current cart.

    name => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 description

Contains the description of the current cart.

    description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => undef
    }

=head1 SEE ALSO

L<Handel::Schema::DBIC::Cart::Item>, L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
