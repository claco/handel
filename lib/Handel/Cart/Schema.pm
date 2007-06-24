# $Id$
package Handel::Cart::Schema;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Schema/;
};

__PACKAGE__->load_classes(qw//, {'Handel::Schema::DBIC' => [qw/Cart Cart::Item/]});

1;
__END__

=head1 NAME

Handel::Cart::Schema - Default Schema class for Handel::Cart

=head1 SYNOPSIS

    use Handel::Cart::Schema;
    use strict;
    use warnings;
    
    my $schema = Handel::Cart::Schema->connect;
    
    my $cart = $schema->resultset("Carts")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Cart is the default schema class used for all reading/writing in
Handel::Cart.

=head1 SEE ALSO

L<Handel::Schema::Cart>, L<Handel::Schema::Cart::Item>, L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
