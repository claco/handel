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
        plan tests => 42;
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

        $checkout->phases({'1234' => 1});

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
        my $checkout = Handel::Checkout->new({phases => {'1234' => 1}});

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Test for Handel::Exception::Constraint if new constant name already exists
{
    try {
        Handel::Checkout->add_phase('CHECKOUT_PHASE_INITIALIZE', 99);

        fail;
    } catch Handel::Exception::Constraint with {
        pass;
    } otherwise {
        fail;
    };
};


## Test for Handel::Exception::Constraint if new constant value already exists
{
    try {
        Handel::Checkout->add_phase('CUSTOM_CHECKOUT_PHASE', CHECKOUT_PHASE_INITIALIZE);

        fail;
    } catch Handel::Exception::Constraint with {
        pass;
    } otherwise {
        fail;
    };
};


## Test for Handel::Exception::Constraint if new constant already exists in caller
sub CUSTOM_CHECKOUT_PHASE_TEST {};
{
    try {
        Handel::Checkout->add_phase('CUSTOM_CHECKOUT_PHASE_TEST', 43, 1);

        fail;
    } catch Handel::Exception::Constraint with {
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
    is(scalar @phases, 2);

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 2);
};


## Set the phases using a string and make sure they stick
{
    my $checkout = Handel::Checkout->new;

    $checkout->phases('CHECKOUT_PHASE_AUTHORIZE');

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
};


## Set the phases using a comma seperated string and make sure they stick
{
    my $checkout = Handel::Checkout->new;

    $checkout->phases('CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_DELIVER');

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 2);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    is($phases->[1], CHECKOUT_PHASE_DELIVER);
};


## Set the phases using a space seperated string and make sure they stick
{
    my $checkout = Handel::Checkout->new;

    $checkout->phases('CHECKOUT_PHASE_AUTHORIZE CHECKOUT_PHASE_DELIVER');

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 2);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    is($phases->[1], CHECKOUT_PHASE_DELIVER);
};


## Set the phases using news' phases option as string and make sure they stick
{
    my $checkout = Handel::Checkout->new({phases => 'CHECKOUT_PHASE_DELIVER'});
    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_DELIVER);
};


## Set the phases using news' phases option as comma seperated string and make
## sure they stick
{
    my $checkout = Handel::Checkout->new({phases => 'CHECKOUT_PHASE_AUTHORIZE,
    CHECKOUT_PHASE_DELIVER'});
    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 2);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    is($phases->[1], CHECKOUT_PHASE_DELIVER);
};


## Set the phases using news' space option as comma seperated string and make
## sure they stick
{
    my $checkout = Handel::Checkout->new({phases => 'CHECKOUT_PHASE_AUTHORIZE
    CHECKOUT_PHASE_DELIVER'});
    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 2);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    is($phases->[1], CHECKOUT_PHASE_DELIVER);
};
