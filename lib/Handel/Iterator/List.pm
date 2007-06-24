# $Id$
## no critic (ProhibitAmbiguousNames)
package Handel::Iterator::List;
use strict;
use warnings;
use overload
        '0+'     => \&count,
        'bool'   => \&count,
        '=='     => \&count,
        fallback => 1;

BEGIN {
    use base qw/Handel::Iterator/;
    __PACKAGE__->mk_group_accessors('inherited', qw/index/);

    use Handel::L10N qw/translate/;
};

__PACKAGE__->index(0);

sub new {
    my $class = shift;

    no strict 'refs';
    throw Handel::Exception::Argument(
        -details => translate('ITERATOR_DATA_NOT_ARRAYREF')
    ) unless ref $_[0]->{'data'} eq 'ARRAY'; ## no critic

    return $class->SUPER::new(@_);
};

sub all {
    my $self = shift;

    return map {$self->create_result($_)} @{$self->data};
};

sub count {
    my $self = shift;

    return scalar @{$self->data};
};

sub first {
    my $self = shift;
    my $result = $self->data->[0];

    return $result ? $self->create_result($result) : undef;
};

sub last {
    my $self = shift;
    my $last = $#{$self->data};
    my $result = $self->data->[$last];

    return $result ? $self->create_result($result) : undef;
};

sub next {
    my $self = shift;
    my $last = $#{$self->data};
    my $index = $self->index;
    my $result;

    if ($index <= $last) {
        $result = $self->data->[$index];

        $self->index($index+1);
    };

    return $result ? $self->create_result($result) : undef;
};

sub reset {
    my $self = shift;

    $self->index(0);

    return;
};

1;
__END__

=head1 NAME

Handel::Iterator::List - Iterator class used for collection looping lists/arrays

=head1 SYNOPSIS

    my $iterator = Handel::Iterator::List->new({
        data         => [$object1, $object2, ...],
        result_class => 'MyResult',
        storage      => $storage
    });
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 DESCRIPTION

Handel::Iterator::List is a used to iterate through results stored in a list
or array reference.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new iterator object. The following options are available:

    my $iterator = Handel::Iterator::List->new({
        data         => [$object1, $object2, ...],
        result_class => 'MyResult',
        storage      => $storage
    });

    my $result = $iterator->first;
    print ref $result; # MyResult

=over

=item data

The data to be iterated through. This should be an array reference.

=item result_class

The name of the class that each result should be inflated into.

=item storage

The storage object that was used to create the results.

=back

=head1 METHODS

=head2 all

Returns all results from current iterator.

    foreach my $result ($iterator->all) {
        print $result->method;
    };

=head2 count

Returns the number of results in the current iterator.

    my $count = $iterator->count;

=head2 create_result

=over

=item Arguments: $result [, $storage]

=back

Returns a new result class object based on the specified result and storage
objects. If no storage object is specified, the storage object passed to C<new>
will be used instead.

This method is used by methods like C<first> and C<next> to to create storage
result objects. There is probably no good reason to use this method directly.

=head2 first

Returns the first result or undef if there are no results.

    my $first = $iterator->first;

=head2 last

Returns the last result or undef if there are no results.

    my $last = $iterator->last;

=head2 next

Returns the next result or undef if there are no results.

    while (my $result = $iterator->next) {
        print $result->method;
    };

=head2 reset

Resets the current result position back to the first result.

    while (my $result = $iterator->next) {
        print $result->method;
    };
    
    $iterator->reset;
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 SEE ALSO

L<Handel::Iterator::DBIC>, L<Handel::Iterator>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
