# $Id$
package Handel::Schema::DBIC::Order::Item;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class/;
    use Handel::Currency;
};

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('order_items');
__PACKAGE__->source_name('Items');
__PACKAGE__->add_columns(
    id => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
    },
    orderid => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
        is_foreign_key => 1
    },
    sku => {
        data_type      => 'varchar',
        size           => 25,
        is_nullable    => 0,
    },
    quantity => {
        data_type      => 'tinyint',
        size           => 3,
        is_nullable    => 0,
        default_value  => 1
    },
    price => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    total => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => undef
    }
);
__PACKAGE__->set_primary_key('id');

1;
__END__

=head1 NAME

Handel::Schema::DBIC::Order::Item - DBIC schema class for order_items table

=head1 SYNOPSIS

    use Handel::Order::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Order::Schema->connect;

    my $item = $schema->resultset("Items")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::DBIC::Order::Item is loaded by Handel::Order::Schema to
read/write data to the order_items table.

=head1 COLUMNS

=head2 id

Contains the primary key for each order item record. By default, this is a uuid
string.

    id => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
    },

=head2 orderid

Contains the foreign key to the orders table.

    orderid => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
        is_foreign_key => 1
    },

=head2 sku

Contains the sku (Stock Keeping Unit), or part number for the current order item.

    sku => {
        data_type      => 'varchar',
        size           => 25,
        is_nullable    => 0,
    },

=head2 quantity

Contains the number of this order item being ordered.

    quantity => {
        data_type      => 'tinyint',
        size           => 3,
        is_nullable    => 0,
        default_value  => 1
    },

=head2 price

Contains the price of the current order item.

    price => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 total

Contains the total cost of the current order item.

    total => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 description

Contains the description of the current order item.

    description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => undef
    }

=head1 SEE ALSO

L<Handel::Schema::DBIC::Order>, L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

