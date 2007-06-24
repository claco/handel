# $Id$
package Handel::Components::DefaultValues;
use strict;
use warnings;
use Scalar::Util qw/blessed reftype/;
use base qw/DBIx::Class Class::Accessor::Grouped/;

BEGIN {
    __PACKAGE__->mk_group_accessors('inherited', qw/default_values/);
};

sub set_default_values {
    my $self = shift;
    my %data = $self->get_columns;
    my $defaults = $self->default_values;

    return unless (defined $defaults && reftype($defaults) eq 'HASH'); ## no critic

    foreach my $default (keys %{$defaults}) {;
        if (!defined $data{$default}) {
            my $value = $defaults->{$default};
            my $new_value;

            if (reftype($value) && reftype($value) eq 'CODE') {
                $new_value = $value->($self);
            } elsif (!reftype($value)) {
                $new_value = $value;
            } else {
                next;
            };
            my $accessor = $self->column_info($default)->{'accessor'};
            if (!$accessor) {
                $accessor = $default;
            };
            
            $self->$accessor($new_value);
        };
    };

    return;
};

sub insert {
    my $self = shift;
    $self->set_default_values;

    return $self->next::method(@_);
};

sub update {
    my $self = shift;
    $self->set_default_values;

    return $self->next::method(@_);
};

1;
__END__

=head1 NAME

Handel::Components::DefaultValues - Set default values for undefined columns

=head1 SYNOPSIS

    package MySchema::Table;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components('+Handel::Component::DefaultValues');
    __PACKAGE__->default_values({
        col1 => 0,
        col2 => 'My New Item',
        col3 => \&subref
    });
    
    1;

=head1 DESCRIPTION

Handel::Components::DefaultValues is a simple way to set default column values
before inserts/updates.

There is no real reason to load this component into your schema table classes
directly. If you add default values using Handel::Storage->default_values, this
component will be loaded into the appropriate schema source class automatically.

=head1 METHODS

=head2 default_values

=over

=item Arguments: \%values

=back

Gets/sets the default values to be used for this result sources columns. Hash
values can be either simple scalar values or code references that will be
executed and their return values inserted into the columns.

Note: Always use the real column name in the database, not the accessor alias
for the column.

=head2 insert

Calls C<set_default_values> and then inserts the row. See
L<DBIx::Class::Row/insert> for more information about insert.

=head2 update

Calls C<set_default_values> and then updates the row. See
L<DBIx::Class::Row/update> for more information about update.

=head2 set_default_values

This loops through all of the configured default values and sets the appropriate
column to that value if the column is undefined.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
