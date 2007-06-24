#!perl -wT
# $Id$
## no critic (RequireTestLabels)
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    require Handel::Test;
    use Handel::TestHelper qw/comp_to_file/;
    use File::Spec::Functions qw/catfile/;

    Handel::Test::plan(skip_all => 'set TEST_HTTP to enable this test') unless $ENV{TEST_HTTP};

    eval 'use Apache::Test 1.27';
    Handel::Test::plan(skip_all =>
        'Apache::Test 1.27 not installed') if $@;

    eval 'use DBD::SQLite';
    Handel::Test::plan(skip_all =>
        'DBD::SQLite not installed') if $@;
};

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
Handel::Test->init_schema(eval_deploy => 1, clear => 1, db_file => 'axkit.db');

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
