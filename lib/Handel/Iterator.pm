package Handel::Iterator;
use strict;
use warnings;

BEGIN {
    use base 'Class::DBI::Iterator';
};

1;
__END__

=head1 NAME

Handel::Iterator - Iterator class used for collection looping

=head1 VERSION

    $Id$

=head1 SYNOPSIS

    use Handel::Cart;

    my $cart = Handel::Cart->new({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };

=head1 DESCRIPTION

C<Handel::Iterator> is used internally by C<Handel::Cart> to iterate through
collections of carts and cart items. At this point, there should be no reason to
use it directly.

=head1 SEE ALSO

L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/



