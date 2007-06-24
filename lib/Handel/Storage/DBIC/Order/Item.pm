# $Id$
package Handel::Storage::DBIC::Order::Item;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC/;
    use Handel::Constraints qw/:all/;
};

__PACKAGE__->setup({
    schema_class     => 'Handel::Order::Schema',
    schema_source    => 'Items',
    currency_columns => [qw/price total/],
    constraints      => {
        quantity     => {'Check Quantity' => \&constraint_quantity},
        price        => {'Check Price'    => \&constraint_price},
        total        => {'Check Total'    => \&constraint_price},
        id           => {'Check Id'       => \&constraint_uuid},
        orderid      => {'Check Order Id' => \&constraint_uuid}
    },
    default_values   => {
        id           => sub {__PACKAGE__->new_uuid(shift)},
        price        => 0,
        quantity     => 1,
        total        => 0
    }
});

1;
__END__

=head1 NAME

Handel::Storage::DBIC::Order::Item - Default storage configuration for Handel::Order::Item

=head1 SYNOPSIS

    package Handel::Order::Item;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::DBIC::Order::Item');

=head1 DESCRIPTION

Handel::Storage::DBIC::Order::Item is a subclass of
L<Handel::Storage::DBIC|Handel::Storage::DBIC> that contains all of the default
settings used by Handel::Order::Item.

=head1 SEE ALSO

L<Handel::Order::Item>, L<Handel::Storage::DBIC>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
