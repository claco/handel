#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    #diag "Waiting on Module::Pluggable 2.9 Taint Fixes";
    eval 'require DBD::SQLite';
    eval 'use Module::Pluggable 2.9';
    if($@) {
        #plan skip_all => 'DBD::SQLite not installed';
        plan skip_all => 'Module::Pluggable 2.9 not installed';
    } else {
        plan tests => 11;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
};


## Check for Handel::Exception::Argument when we pass something other
## than an array reference
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->phases('1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};



## Check for Handel::Exception::Argument when we pass something other
## than an array reference in news' phases option
{
    try {
        my $checkout = Handel::Checkout->new({phases => '1234'});
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Set the phases and make sure they stick
{
    my $checkout = Handel::Checkout->new;

    $checkout->phases([CHECKOUT_PHASE_AUTHORIZE]);

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
};


## Set the phases using news' phases option and make sure they stick
{
    my $checkout = Handel::Checkout->new({phases => [CHECKOUT_PHASE_DELIVER]});
    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_DELIVER);
};