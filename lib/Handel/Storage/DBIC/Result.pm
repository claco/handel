# $Id$
package Handel::Storage::DBIC::Result;
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::Result/;
};

sub delete {
    return shift->storage_result->delete(@_);
};

sub discard_changes {
    return shift->storage_result->discard_changes(@_);
};

sub has_column {
    my ($self, $column) = @_;

    return $self->storage_result->has_column_loaded($column);
};

sub update {
    return shift->storage_result->update(@_);
};

1;
__END__

=head1 NAME

Handel::Storage::DBIC::Result - Result object returned by DBIC storage operations

=head1 SYNOPSIS

    use Handel::Storage::DBIC::Cart;
    
    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    print $result->id;
    print $result->name;

=head1 DESCRIPTION

Handel::Storage::DBIC::Result is a generic wrapper around DBIC objects returned
by various Handel::Storage::DBIC operations. Its main purpose is to abstract
storage result objects away from the Cart/Order/Item classes that use them and
deal with any DBIC specific issues. Each result is assumed to exposed methods
for each 'property' or 'column' it has, as well as support the methods
described below.

=head1 METHODS

=head2 delete

Deletes the current result and all of it's associated items from the current
storage.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $result->delete;

=head2 discard_changes

Discards all changes made since the last successful update.

=head2 has_column

=over

=item Arguments: $column

=back

Returns true if the column exists in the current result object.

=head2 update

=over

=item Arguments: \%data

=back

Updates the current result with the data specified.

    my $storage = Handel::Storage::DBIC::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->update({
        name => 'My Cart'
    });

=head1 SEE ALSO

L<Handel::Storage::Result>, L<DBIx::Class>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
