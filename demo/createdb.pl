#!perl -wT
# $Id$
use strict;
use warnings;
use lib '../t/lib';
use Handel::TestHelper qw(executesql);

my $dbfile  = 'cart.db';
my $db      = "dbi:SQLite:dbname=$dbfile";
my $create  = '../t/sql/cart_create_table.sql';

executesql($db, $create);