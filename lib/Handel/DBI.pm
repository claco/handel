package Handel::DBI;
use strict;
use warnings;

BEGIN {
    use base 'Class::DBI';
    use Handel::ConfigReader;
    use Handel::Exception;
    use Handel::L10N qw(translate);

};

my $cfg = Handel::ConfigReader->new();
my $db_driver = $cfg->get('db_driver');
my $db_host   = $cfg->get('db_host');
my $db_port   = $cfg->get('db_port');
my $db_name   = $cfg->get('db_name');
my $db_user   = $cfg->get('db_user');
my $db_pass   = $cfg->get('db_pass');

my $datasource = "dbi:$db_driver:dbname=$db_name";

if ($db_host) {
    $datasource .= ";host=$db_host";
};

if ($db_port) {
    $datasource .= ";port=$db_port";
};

__PACKAGE__->connection($datasource, $db_user, $db_pass);

sub _croak {
    my ($self, $message, %info) = @_;
    my $method = $info{method} || '';

    if ($method eq 'validate_column_values') {
        my $data = $info{data};
        throw Handel::Exception::Constraint(
            -details =>
            join(' ' . translate('has invalid value') . ', ', keys %$data)
        );
    } elsif ($method eq 'create') {
        my $details;

        if ($message =~ /insert new.*column\s+(.*)\s+is not unique/) {
            $details = translate("[_1] value already exists", $1);
        } else {
            $details = $message;
        };
        throw Handel::Exception::Constraint(-details => $details );
    } else {
        throw Handel::Exception(-text => $message);
    };

    return;
};

sub has_wildcard {
    my $filter = shift;

    for (values %{$filter}) {
        return 1 if $_ =~ /\%/;
    };

    return undef;
};

sub uuid {
    my $uuidstring = '';

    if (eval{require UUID}) {
        my $uuid;
        UUID::generate($uuid);
        UUID::unparse($uuid, $uuidstring);
    } elsif (eval{require Data::UUID}) {
        my $ug = Data::UUID->new;
        my $uuid = $ug->create;
        $uuidstring = $ug->to_string($uuid);
    } elsif (eval{
            # for some reason 'no warnings' won't squelch
            # the 'too late for INIT' warning in Win32::API::Type
            local $^W = 0;
            require Win32::Guidgen;
        }) {
        $uuidstring = Win32::Guidgen::create();
    } elsif (eval{require Win32API::GUID}) {
        $uuidstring = Win32API::GUID::CreateGuid();
    } else {
        throw Handel::Exception(
            -text => 'Required modules not found',
            -details => 'UUID/Data::UUID'
        );
    };

    $uuidstring =~ s/^{//;
    $uuidstring =~ s/}$//;

    return uc($uuidstring);
};

1;
__END__

=head1 NAME

Handel::DBI - Base DBI class used by cart/order objects

=head1 SYNOPSIS

    use Handel::DBI;

    my $newid = Handel::DBI::uuid;
    my $newid = Handel::DBI->uuid;
    my $newid = Handel::Cart->uuid;
    my $newid = Handel::Cart::Item->uuid;
    ..etc...

=head1 VERSION

    $Id$

=head1 DESCRIPTION

This is the main base class for Handel objects that access the database. There
shouldn't be and reason to use this module directly for now.

=head1 FUNCTIONS

=head2 C<uuid>

Returns a guid/uuid using the first available uuid generation module.
The support modules are L<UUID>, L<Data::UUID>, L<Win32::Guidgen>, and
L<Win32API::GUID>.

    use Handel::DBI;

    my $newid = Handel::DBI::uuid;

Since C<Handel::Cart> and C<Handel::Cart::Item> are subclasses of
C<Handel::DBI>, C<uuid> is available within those modules as a method/function
as well

    use Handel::Cart;

    my $newid = Handel::Cart->uuid;

=head2 C<has_wildcard>

Inspects the supplied search filter to determine whether it contains wildcard
searching. Returns 1 if the filter contains SQL wildcards, other it returns
C<undef>.

    has_wildcard({sku => '1234'}); # 1
    has_wildcard((sku => '12%'));  # undef

This is used by C<Handel::Cart-E<gt>items> and
C<Handel::Cart::load> to determine which L<Class::DBI> methods to call (search
vs. search_like).

=head1 ENVIRONMENT VARIABLES

For now, C<Handel::DBI> constructs its connection string using the following
variables:

=over

=item C<db_driver>

The name of the DBD driver. Defaults to C<mysql>.

=item C<db_host>

The name of the database server. Defaults to C<localhost>.

=item C<db_port>

The port of the database server. Defaults to C<3306>.

=item C<db_name>

The name of the database. Defaults to C<commerce>.

=item C<db_user>

The user name used to connect to the server. Defaults to C<commerce>.

=item C<db_pass>

The password used to connect to the server. Defaults to C<commerce>.

=back

For now, these can either be set in C<ENV>, or using PerlSetVar in C<httpd.conf>.

At some point, this needs to be reworked into a more generic config loader so we
can use $ENV, httpd.conf directives, of config files, etc.

=head1 SEE ALSO

L<UUID>, L<Data::UUID>, L<Win32::Guidgen>, L<Win32API::GUID>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/
