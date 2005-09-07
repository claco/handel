# $Id$
package Catalyst::Helper::Model::Handel::Order;
use strict;
use warnings;

sub mk_compclass {
    my ($self, $helper, $dsn, $user, $pass) = @_;
    my $file = $helper->{file};
    $helper->{dsn}  = $dsn  || '';
    $helper->{user} = $user || '';
    $helper->{pass} = $pass || '';

    $helper->render_file('model', $file);
};

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{test};
    my $name = $helper->{name};

    $helper->render_file('test', $test);
};

1;
__DATA__
__model__
package [% class %];
use strict;
use warnings;
use base 'Handel::Order';

{
    $^W = 0;
    Handel::DBI->connection('[% dsn %]', '[% user %]', '[% pass %]');
};

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__END__

=head1 NAME

Catalyst::Helper::Model::Handel::Order - Helper for Handel::Order Models

=head1 SYNOPSIS

    script/create.pl model Order Handel::Order dsn user password

=head1 DESCRIPTION

A Helper for creating models based on Handel::Order objects.

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Order Model class for you.

=head2 mk_comptest

Makes a Handel::Order Model test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/