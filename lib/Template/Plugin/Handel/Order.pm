# $Id$
package Template::Plugin::Handel::Order;
use strict;
use warnings;
use base qw/Template::Plugin/;
use Handel::Constants ();

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {_CONTEXT => $context}, 'Template::Plugin::Handel::Order::Proxy';

    foreach my $const (@Handel::Constants::EXPORT_OK) {
        if ($const =~ /^[A-Z]{1}/) {
            $self->{$const} = Handel::Constants->$const;
        };
    };
    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

package Template::Plugin::Handel::Order::Proxy;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->init_storage;

sub search {
    my ($self, $filter) = @_;
    my $iterator = $self->SUPER::search($filter);

    return $iterator;
};

sub items {
    my ($self, $filter) = @_;
    my $iterator = $self->SUPER::items($filter);

    return $iterator;
};

sub uuid {
    return shift->storage->new_uuid;
};

*guid = \&uuid;

1;
__END__

=head1 NAME

Template::Plugin::Handel::Order - Template Toolkit plugin for orders

=head1 SYNOPSIS

    [% USE Handel.Order %]
    [% IF (order = Handel.Order.search({id => 'A2CCD312-73B5-4EE4-B77E-3D027349A055'}).first) %]
        [% order.number %]
        [% FOREACH item IN order.items.all %]
            [% item.sku %]
        [% END %]
    [% END %]

=head1 DESCRIPTION

Template::Plugin::Handel::Order is a TT2 (Template Toolkit 2) plugin for
Handel::Order. It's API is exactly the same as Handel::Order.

Handel::Constants are imported into this module automatically. This removes
the need to use Template::Plugin::Handel::Constants separately when working
with orders.

    [% USE ho = Handel.Order %]
    [% order = ho.create(...) %]
    [% order.type(ho.ORDER_TYPE_TEMP) %]

=head1 SEE ALSO

L<Template::Plugin::Handel::Constants>, L<Handel::Constants>, L<Handel::Order>,
L<Template::Plugin>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
