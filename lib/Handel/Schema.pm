# $Id$
package Handel::Schema;
use strict;
use warnings;

BEGIN {
    use Handel::ConfigReader;
    use base qw/DBIx::Class::Schema/;
};

# this needs to be factored into ConfigReader!
sub connect {
    my ($self, $dsn, $user, $pass, $opts) = @_;
    my $cfg = Handel::ConfigReader->instance;

    ## I hate this vs. ||=, but it just wouldn't cover on some perl versions
    if (!$dsn) {
        $dsn = $cfg->{'HandelDBIDSN'} || $cfg->{'db_dsn'};
    };
    if (!$user) {
        $user = $cfg->{'HandelDBIUser'} || $cfg->{'db_user'};
    };
    if (!$pass) {
        $pass = $cfg->{'HandelDBIPassword'} || $cfg->{'db_pass'};
    };
    if (!$opts) {
        $opts = {AutoCommit => 1};
    };

    my $db_driver = $cfg->{'HandelDBIDriver'} || $cfg->{'db_driver'};
    my $db_host   = $cfg->{'HandelDBIHost'}   || $cfg->{'db_host'};
    my $db_port   = $cfg->{'HandelDBIPort'}   || $cfg->{'db_port'};
    my $db_name   = $cfg->{'HandelDBIName'}   || $cfg->{'db_name'};


    if (!$dsn && $db_driver && $db_name) {
        $dsn = "dbi:$db_driver:dbname=$db_name";

        if ($db_host) {
            $dsn .= ";host=$db_host";
        };

        if ($db_host && $db_port) {
            $dsn .= ";port=$db_port";
        };
    };

    return $self->next::method($dsn, $user, $pass, $opts);
};

1;
__END__

=head1 NAME

Handel::Schema - Base class for cart/order schemas

=head1 SYNOPSIS

    package MySchema;
    use strict;
    use warnings;
    use base qw/Handel::Schema/;
    
    __PACKAGE__->load_classes(qw//, {'MySchema' => [qw/TableClass OtherTableClass/]});

=head1 DESCRIPTION

Handel::Schema is the base class for the cart/order schemas. If you want to
create your own cart or order schema, simply subclass Handel::Schema and load
your classes.

=head1 METHODS

=head2 connect

=over

=item Arguments: $dsn, $user, $pass, \%attr

=back

Establishes a connection to the database and returns a new schema instance. If
no connection information is supplied, the connection information will be read
from C<ENV> or ModPerl using the configuration options available in the
specified C<config_class>. By default, this will be
L<Handel::ConfigReader|Handel::ConfigReader>.

=head1 SEE ALSO

L<Handel::ConfigReader>, L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
