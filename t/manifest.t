#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

    eval 'use Test::CheckManifest 0.09';
    if($@) {
        plan skip_all => 'Test::CheckManifest 0.09 not installed';
    };
};

ok_manifest({
    exclude => ['/t/var', '/cover_db', '/t/conf', '/t/logs/', '/t/htdocs/index.html'],
    filter  => [qr/\.svn/, qr/cover/, qr/\.tws/, qr/(SMOKE$|TEST$)/],
    bool    => 'or'
});
