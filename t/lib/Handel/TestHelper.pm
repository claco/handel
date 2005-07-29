# $Id$
package Handel::TestHelper;
use strict;
use warnings;
use DBI;
use FileHandle;
use vars qw(@EXPORT_OK);
use base 'Exporter';

@EXPORT_OK = qw(executesql comp_to_file preparetables);

sub executesql {
    my ($db, $sqlfile) = @_;

    return unless ($db || $sqlfile);

    my $dbh = DBI->connect($db);
    open SQL, "< $sqlfile";
    while (<SQL>) {
        $dbh->do($_);
    };
    close SQL;
    $dbh->disconnect;
    undef $dbh;
};

sub preparetables {
    my ($db, $groups, $populate) = @_;
    my %tables = (
        cart => {
            exists => 'cart',
            create => 'cart_create_table.sql',
            data   => 'cart_fake_data.sql',
            delete => 'cart_delete_data.sql'
        },
        order => {
            exists => 'orders',
            create => 'order_create_table.sql',
            data   => 'order_fake_data.sql',
            delete => 'order_delete_data.sql'
        }
    );

    return unless scalar @{$groups};

    my $dbh = DBI->connect($db);
    foreach my $group (@{$groups}) {
        return unless exists $tables{$group};

        my $data = $tables{$group};
        my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='" . $data->{'exists'} . "'");

        if ($count == 0) {
            open SQL, "< t/sql/" . $data->{'create'};
            while (<SQL>) {
                $dbh->do($_);
            };
            close SQL;
        } elsif ($count == 1) {
            open SQL, "< t/sql/" . $data->{'delete'};
            while (<SQL>) {
                $dbh->do($_);
            };
            close SQL;
        };
        if ($populate) {
            open SQL, "< t/sql/" . $data->{'data'};
            while (<SQL>) {
                $dbh->do($_);
            };
            close SQL;
        };
    };
    $dbh->disconnect;
    undef $dbh;
};

sub comp_to_file {
    my ($string, $file) = @_;

    return 0 unless $string && $file && -e $file && -r $file;

    $string =~ s/\n//g;
    $string =~ s/\s//g;
    $string =~ s/\t//g;

    my $fh = FileHandle->new("<$file");
    if (defined $fh) {
        local $/ = undef;
        my $contents = <$fh>;
        $contents =~ s/\n//g;
        $contents =~ s/\s//g;
        $contents =~ s/\t//g;

        # remove the tt2 and xml Ids
        $contents =~ s/<!--.*-->//;
        $contents =~ s/\[%#.*%\]//;

        undef $fh;

        if ($string eq $contents) {
            return (1, $string, $contents);
        } else {
            return (0, $string, $contents);
        };
    };

    return 0;
};

1;