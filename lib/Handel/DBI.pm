# $Id: DBI.pm 4 2004-12-28 03:01:15Z claco $
package Handel::DBI;
use strict;
use warnings;

BEGIN {
    use base 'Class::DBI';
    use Handel::Exception;
};

my $db_driver  = $ENV{'db_driver'} || 'mysql';
my $db_host    = $ENV{'db_host'}   || 'localhost';
my $db_port    = $ENV{'db_port'}   || 3306;
my $db_name    = $ENV{'db_name'}   || 'commerce';
my $db_user    = $ENV{'db_user'}   || 'commerce';
my $db_pass    = $ENV{'db_pass'}   || 'commerce';
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
            -details => join(' has invalid value , ', keys %$data)
        );
    } elsif ($method eq 'create') {
        my $details;

        if ($message =~ /insert new.*column\s+(.*)\s+is not unique/) {
            $details = "$1 value already exists";
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
    my ($uuid, $uuidstring);

    eval {require UUID};
    if (!$@) {
        UUID::generate($uuid);
        UUID::unparse($uuid, $uuidstring);
    };

    if (!$uuidstring) {
        eval {require Data::UUID};
        if (!$@) {
            my $ug = Data::GUID->new;
            $uuid = $ug->create;
            $uuidstring = $ug->to_string($uuid);
        } else {
            throw Handel::Exception(
                -text => 'Required modules not found',
                -details => 'UUID/Data::UUID',
            );
        };
    };

    return uc($uuidstring);
};

1;
__END__

=head1 NAME

Handel::DBI - DBI

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/

=head1 FUNCTIONS

=over

=item C<uuid>

=item C<has_wildcard>

=back

