# $Id$
package Handel::Components::Constraints;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
    use Handel::Exception;
    use Handel::L10N qw/translate/;

    __PACKAGE__->mk_group_accessors('inherited', qw/constraints/);
};

sub add_constraint {
    my ($self, $column, $name, $constraint) = @_;
    my $constraints = $self->constraints || {};

    throw Handel::Exception::Argument(
        -details => translate('COLUMN_NOT_SPECIFIED')
    ) unless $column; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CONSTRAINT_NAME_NOT_SPECIFIED')
    ) unless $name; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CONSTRAINT_NOT_SPECIFIED')
    ) unless ref $constraint eq 'CODE'; ## no critic

    if (!exists $constraints->{$column}) {
        $constraints->{$column} = {};
    };

    $constraints->{$column}->{$name} = $constraint;

    $self->constraints($constraints);

    return;
};

sub check_constraints { ## no critic (RequireFinalReturn)
    my $self = shift;
    my $constraints = $self->constraints;

    return 1 if !scalar keys(%{$constraints});

    my %data = $self->get_columns();
    my $source = $self->result_source;
    my %failed;

    foreach my $column (keys %{$constraints}) {
        my $value = $data{$column};
        
        foreach my $name (keys %{$constraints->{$column}}) {
            if (my $sub = $constraints->{$column}->{$name}) {
                if (!$sub->($value, $source, $column, \%data)) {
                    $failed{$name} = $column;
                };
            };
        };
    };

    if (scalar keys %failed) {
        my @details = map {"$_(" . $failed{$_} . ')'} keys %failed;
        
        $self->throw_exception(
            Handel::Exception::Constraint->new(-details => join(', ', @details))
        );
    } else {
        $self->set_columns(\%data);
        return 1;
    };
};

sub insert {
    my $self = shift;
    $self->check_constraints;

    return $self->next::method(@_);
};

sub update {
    my $self = shift;
    $self->check_constraints;

    return $self->next::method(@_);
};

1;
__END__

=head1 NAME

Handel::Components::Constraints - Column constraints for schemas

=head1 SYNOPSIS

    package MySchema::Table;
    use strict;
    use warnings;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components('+Handel::Component::Constraints');
    __PACKAGE__->add_constraint('column', 'Constraint Name' => \&checker);
    
    1;

=head1 DESCRIPTION

Handel::Components::Constraints is a simple way to validate column data during
inserts/updates using subroutines. It mostly acts as a compatibility layer
for subclasses that used C<add_constraint> when Handel used Class::DBI.

There is no real reason to load this component into your schema table classes
directly. If you add constraints using Handel::Storage->add_constraint, this
component will be loaded into the appropriate schema source class automatically.

=head1 METHODS

=head2 add_constraint

=over

=item Arguments: $column, $name, \&sub

=back

Adds a named constraint for the specified column.

    __PACKAGE__->add_constraint('quantity', 'Check Quantity' => \%check_qty);

Note: Always use the real column name in the database, not the accessor alias
for the column.

=head2 check_constraints

This loops through all of the configured constraints, calling the specified
\&sub. Each sub will receive the following arguments:

    sub mysub {
        my ($value, $source, $column, \%data) = @_;
        
        if ($value) {
            return 1;
        } else {
            return 0;
        };
    };

=over

=item value

The value of the column to be checked.

=item source

The result object for the row being updated/inserted.

=item column

The name of the column being checked.

=item data

A hash reference containing all of the columns and their values. Changing any
values in the hash will also change the value inserted/updated in the
database.

=back

=head2 insert

Calls C<check_constraints> and then inserts the row. See
L<DBIx::Class::Row/insert> for more information about insert.

=head2 update

Calls C<check_constraints> and then updates the row. See
L<DBIx::Class::Row/update> for more information about update.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
