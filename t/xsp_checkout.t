#!perl -wT
# $Id$
use strict;
use warnings;
require Test::More;
use lib 't/lib';
use Handel::TestHelper qw(preparetables comp_to_file);

Test::More::plan(skip_all => 'set TEST_HTTP to enable this test') unless $ENV{TEST_HTTP};

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
    'Apache::Test 1.16 not installed') if $@;

eval 'use DBD::SQLite';
Test::More::plan(skip_all =>
    'DBD::SQLite not installed') if $@;

my @tests = (
    'checkout_plugins.xsp',
    'checkout_messages.xsp',
    'checkout_phases.xsp',
    'checkout_process.xsp',
    'checkout_order.xsp'
);

require Apache::TestUtil;
Apache::TestUtil->import(qw(t_debug));
Apache::TestRequest->import(qw(GET));
Apache::Test::plan(tests => (scalar @tests * 2),
    need('AxKit', 'mod_perl', need_apache(1), need_lwp())
);

my $docroot = Apache::Test::vars('documentroot');

## Setup SQLite DB for tests
{
    my $dbfile  = "$docroot/xsp.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";

    preparetables($db, [qw(cart order)], 1);
};

LOOP: foreach (@tests) {
    my $r = GET("/axkit/$_");

    ok($r->code == 200);

    my ($ok, $response, $file) = comp_to_file($r->content, "$docroot/axkit/out/$_.out");

    t_debug($_);
    t_debug("HTTP Status: " . $r->code);
    t_debug("Expected:\n", $file);
    t_debug("Received:\n", $response);

    ok($ok);
};
