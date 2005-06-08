#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Constants', qw(:checkout));
};

ok(!constraint_checkout_phase('junk.foo'), 'alpha gibberish type');
ok(!constraint_checkout_phase(-14), 'negative number type');
ok(!constraint_checkout_phase(23), 'out of range type');
ok(constraint_checkout_phase(CHECKOUT_PHASE_INITIALIZE), 'checkout initialize phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_VALIDATE), 'checkout validation phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_AUTHORIZE), 'checkout authorization phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_DELIVER), 'checkout delivery phase');
