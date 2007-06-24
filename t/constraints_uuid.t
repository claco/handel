#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 7;

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

ok(!constraint_uuid(undef),        'value is undefined');
ok(!constraint_uuid(''),           'value is empty string');
