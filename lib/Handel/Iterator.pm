# $Id$
## no critic (ProhibitAmbiguousNames, RequireFinalReturn)
package Handel::Iterator;
use strict;
use warnings;
use overload
        '0+'     => \&count,
        'bool'   => \&count,
        '=='     => \&count,
        fallback => 1;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('inherited', qw/data result_class storage/);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
};

sub new {
    my ($class, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref $options eq 'HASH'; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('NO_ITERATOR_DATA')
    ) unless $options->{'data'}; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT_CLASS')
    ) unless $options->{'result_class'}; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('NO_STORAGE')
    ) unless $options->{'storage'}; ## no critic

    return bless $options, $class;
};

sub all {
    throw Handel::Exception::Virtual;
};

sub count {
    throw Handel::Exception::Virtual;
};

sub first {
    throw Handel::Exception::Virtual;
};

sub last {
    throw Handel::Exception::Virtual;
};

sub next {
    throw Handel::Exception::Virtual;
};

sub reset {
    throw Handel::Exception::Virtual;
};

sub create_result {
    my ($self, $result, $storage) = @_;
    if (!$storage) {
        $storage = $self->storage;
    };

    throw Handel::Exception::Argument( -text =>
        translate('NO_RESULT')
    ) unless $result; ## no critic

    throw Handel::Exception::Argument( -text =>
        translate('NO_STORAGE')
    ) unless $storage; ## no critic

    return $self->result_class->create_instance(
        $result, $storage
    );
};

1;
__END__

=head1 NAME

Handel::Iterator - Iterator base class used for collection looping

=head1 SYNOPSIS

    my $iterator = Handel::Iterator::Custom->new({
        data         => [$object1, $object2, ...],
        result_class => 'MyResult',
        storage      => $storage
    });
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 DESCRIPTION

Handel::Iterator is a base class used to create custom iterators for
DBIx::Class resultsets and lists of results.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new iterator object. The following options are available:

    my $iterator = Handel::Iterator::Custom->new({
        data         => [$object1, $object2, ...],
        result_class => 'MyResult',
        storage      => $storage
    });

    my $result = $iterator->first;
    print ref $result; # MyResult

=over

=item data

The data to be iterated through. The type of this data depends on the
individual subclass.

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

L<Handel::Iterator::DBIC>, L<Handel::Iterator::List>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
