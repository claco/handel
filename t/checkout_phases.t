#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 17;
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

        fail;
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

        fail;
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


## check scalar/list context returns on phases default
{
    my $checkout = Handel::Checkout->new;
    my @phases = $checkout->phases;
    ok(scalar @phases >= 1);

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    ok(scalar @{$phases} >= 1);
};


## check scalar/list context returns on set phases
{
    my $checkout = Handel::Checkout->new({phases => [CHECKOUT_PHASE_DELIVER, CHECKOUT_PHASE_INITIALIZE]});
    my @phases = $checkout->phases;
    ok(scalar @phases >= 1);

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    ok(scalar @{$phases} >= 1);
};