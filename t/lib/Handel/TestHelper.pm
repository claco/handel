# $Id$
package Handel::TestHelper;
use strict;
use warnings;
use DBI;
use FileHandle;
use vars qw(@EXPORT_OK);
use base 'Exporter';

@EXPORT_OK = qw(executesql comp_to_file);

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
        $contents =~ s/<!--.*-->//;
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