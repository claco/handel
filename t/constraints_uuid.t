#!perl -wT
# $Id: constraints_uuid.t 4 2004-12-28 03:01:15Z claco $
use Test::More tests => 5;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
};

ok(!constraint_uuid('0000-0000-0000-0000'),
    'invalid uuid pattern');

ok(!constraint_uuid('HHHHHHHH-HHHH-HHHH-HHHH-HHHHHHHHHHHH'),
    'uuid out of range');

ok(!constraint_uuid('{D597DEED-5B9F-11D1-8DD2-00AA004ABD5E}'),
    'uuid with brackets'
);

ok(constraint_uuid('D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'),
    'valid uuid'
);
