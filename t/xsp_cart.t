#!perl -wT
# $Id$
use strict;
use warnings;
require Test::More;
use lib 't/lib';
use Handel::TestHelper;

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
        'Apache::Test 1.16 not installed') if $@;

Apache::TestRequest->import(qw(GET));
Apache::Test::plan(tests => 3,
    need('AxKit', 'mod_perl', need_apache(1), need_lwp())
);

## Setup SQLite DB for tests
{
    my $root    = Apache::Test::vars('documentroot');
    my $dbfile  = "$root/cart.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';
    my $data    = 't/sql/cart_fake_data.sql';

    unlink $dbfile;
    Handel::TestHelper::executesql($db, $create);
    Handel::TestHelper::executesql($db, $data);
};



my $r = GET('/cart_load.xsp');
ok($r->code == 200);
warn $r->content;

#$r = GET('/cart_load_filter.xsp');
#ok($r->code == 200);
#warn $r->content;

#$r = GET('/cart_load_all.xsp');
#ok($r->code == 200);
#warn $r->content;