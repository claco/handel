# $Id$
package Handel::Schema::DBIC::Order;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class/;
    use DateTime;
};

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table('orders');
__PACKAGE__->source_name('Orders');
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
    number => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },
    created => {
        data_type     => 'datetime',
        is_nullable   => 1,
        default_value => undef,
        extra         => {
            timezone  => 'UTC'
        }
    },
    updated => {
        data_type     => 'datetime',
        is_nullable   => 1,
        default_value => undef,
        extra         => {
            timezone  => 'UTC'
        }
    },
    comments => {
        data_type     => 'varchar',
        size          => 100,
        is_nullable   => 1,
        default_value => undef
    },
    shipmethod => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },
    shipping => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    handling => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    tax => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    subtotal => {
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
    billtofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },
    billtocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptosameasbillto => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 1
    },
    shiptofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },
    shiptocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(items => 'Handel::Schema::DBIC::Order::Item', {'foreign.orderid' => 'self.id'});

1;
__END__

=head1 NAME

Handel::Schema::DBIC::Order - DBIC schema class for order table

=head1 SYNOPSIS

    use Handel::Order::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Order::Schema->connect;

    my $cart = $schema->resultset("Orders")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Order is loaded by Handel::Order::Schema to read/write data to
the order table.

=head1 COLUMNS

=head2 id

Contains the primary key for each order record. By default, this is a uuid string.

    id => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },

=head2 shopper

Contains the keys used to tie each order to a specific shopper. By default,
this is a uuid string.

    shopper => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },

=head2 type

Contains the type for this order. The current values are ORDER_TYPE_TEMP and
ORDER_TYPE_SAVED from Handel::Constants.

    type => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 0
    },

=head2 number

The order number for this order.

    number => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },

=head2 created

The date this order record was created.

    created => {
        data_type     => 'datetime',
        is_nullable   => 1,
        default_value => undef
    },

=head2 updated

The date this order record was last updated.

    updated => {
        data_type     => 'datetime',
        is_nullable   => 1,
        default_value => undef
    },

=head2 comments

Any user comments for this order.

    comments => {
        data_type     => 'varchar',
        size          => 100,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shipmethod

The shipping method for this order.

    shipmethod => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shipping

The shipping cost for this order.

    shipping => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 handling

The handling charge for this order.

    handling => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 tax

The tax amount for this order.

    tax => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 subtotal

The subtotal of all the items on this order.

    subtotal => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 total

The total cost of the current order.

    total => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },

=head2 billtofirstname

The first name for the billing address for this order.

    billtofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtolastname

The last name for the billing address for this order.

    billtolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtoaddress1

The billing address line 1 for this order.

    billtoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtoaddress2

The billing address line 2 for this order.

    billtoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtoaddress3

The billing address line 3 for this order.

    billtoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtocity

The billing address city for this order.

    billtocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtostate

The billing address state/province for this order.

    billtostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtozip

The billing address zip/postal code for this order.

    billtozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtocountry

The billing address country for this order.

    billtocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtodayphone

The billing address daytime phone number for this order.

    billtodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtonightphone

The billing address night time phone number for this order.

    billtonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtofax

The billing address fax number for this order.

    billtofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 billtoemail

The billing address email address for this order.

    billtoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptosameasbillto

When set to true, the shipping address is the same as the billing address.

    shiptosameasbillto => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 1
    },

=head2 shiptofirstname

The first name for the shipping address for this order.

    shiptofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptolastname

The last name for the shipping address for this order.

    shiptolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptoaddress1

The shipping address line 1 for this order.

    shiptoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptoaddress2

The shipping address line 2 for this order.

    shiptoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptoaddress3

The shipping address line 3 for this order.

    shiptoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptocity

The shipping address city for this order.

    shiptocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptostate

The shipping address state/province for this order.

    shiptostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptozip

The shipping address zip/postal code for this order.

    shiptozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptocountry

The shipping address country for this order.

    shiptocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptodayphone

The shipping address daytime phone number for this order.

    shiptodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptonightphone

The shipping address night time phone number for this order.

    shiptonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptofax

The shipping address fax number for this order.

    shiptofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },

=head2 shiptoemail

The shipping address email address for this order.

    shiptoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    }

=head1 SEE ALSO

L<Handel::Schema::DBIC::Order::Item>, L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
