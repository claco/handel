# $Id: TestHelper.pm 4 2004-12-28 03:01:15Z claco $
package Handel::TestHelper;
use strict;
use warnings;
use DBI;

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

1;