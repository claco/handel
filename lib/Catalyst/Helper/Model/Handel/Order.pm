# $Id$
package Catalyst::Helper::Model::Handel::Order;
use strict;
use warnings;

BEGIN {
    use Catalyst 5.7001;
};

=head1 NAME

Catalyst::Helper::Model::Handel::Order - Helper for Handel::Order Models

=head1 SYNOPSIS

    script/create.pl model <newclass> Handel::Order <dsn> [<username> <password>]
    script/create.pl model Order Handel::Order dbi:mysql:localhost myuser mysecret

=head1 DESCRIPTION

A Helper for creating models based on Handel::Order objects.

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Order Model class for you.

=cut

sub mk_compclass {
    my ($self, $helper, $dsn, $user, $pass) = @_;
    my $file = $helper->{file};
    my $app  = $helper->{app};

    $helper->{'dsn'}  = $dsn  || '';
    $helper->{'user'} = $user || '';
    $helper->{'pass'} = $pass || '';

    if ($helper->{'handel_auto_wire_models'}) {
        $helper->{'handel_auto_wireup'} = "order_class => '$app\:\:Order',\n    ";
    };

    return $helper->render_file('model', $file);
};

=head2 mk_comptest

Makes a Handel::Order Model test for you.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    return $helper->render_file('test', $test);
};

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::Model::Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

=cut

1;
__DATA__

=begin pod_to_ignore

__model__
package [% class %];
use strict;
use warnings;

BEGIN {
    use base qw/Catalyst::Model::Handel::Order/;
};

__PACKAGE__->config(
    [% handel_auto_wireup %]connection_info => ['[% dsn %]', '[% user %]', '[% pass %]']
);

=head1 NAME

[% class %] - Catalyst cart model component.

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Catalyst cart model component.

=head1 AUTHOR

[% author %]

=cut

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

BEGIN {
    use_ok('Catalyst::Test', '[% app %]');
    use_ok('[% class %]');
};
__END__
