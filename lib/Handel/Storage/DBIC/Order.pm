# $Id$
package Handel::Storage::DBIC::Order;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC/;
    use Handel::Constants qw/ORDER_TYPE_TEMP/;
    use Handel::Constraints qw/:all/;
};

__PACKAGE__->setup({
    schema_class       => 'Handel::Order::Schema',
    schema_source      => 'Orders',
    item_storage_class => 'Handel::Storage::DBIC::Order::Item',
    constraints        => {
        id             => {'Check Id'       => \&constraint_uuid},
        shopper        => {'Check Shopper'  => \&constraint_uuid},
        type           => {'Check Type'     => \&constraint_order_type},
        shipping       => {'Check Shopping' => \&constraint_price},
        handling       => {'Check Handling' => \&constraint_price},
        subtotal       => {'Check Subtotal' => \&constraint_price},
        tax            => {'Check Tax'      => \&constraint_price},
        total          => {'Check Total'    => \&constraint_price}
    },
    currency_columns => [qw/shipping handling subtotal tax total/],
    default_values => {
        id         => sub {__PACKAGE__->new_uuid(shift)},
        type       => ORDER_TYPE_TEMP,
        shipping => 0,
        handling => 0,
        subtotal => 0,
        tax      => 0,
        total    => 0,
        created  => sub {DateTime->now},
        updated  => sub {DateTime->now}
    }
});

1;
__END__

=head1 NAME

Handel::Storage::DBIC::Order - Default storage configuration for Handel::Order

=head1 SYNOPSIS

    package Handel::Order;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::DBIC::Order');

=head1 DESCRIPTION

Handel::Storage::DBIC::Order is a subclass of
L<Handel::Storage::DBIC|Handel::Storage::DBIC> that contains all of the default
settings used by Handel::Order.

=head1 SEE ALSO

L<Handel::Order>, L<Handel::Storage::DBIC>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
