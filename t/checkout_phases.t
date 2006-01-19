#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 123;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout');
&run('Handel::Subclassing::Checkout');
&run('Handel::Subclassing::CheckoutStash');

sub run {
    my ($subclass) = @_;


    ## Check for Handel::Exception::Argument when we pass something other
    ## than an array reference
    {
        try {
            my $checkout = $subclass->new;

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
            my $checkout = $subclass->new({phases => {'1234' => 1}});

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
            $subclass->add_phase('CHECKOUT_PHASE_INITIALIZE', 99);

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
            $subclass->add_phase('CUSTOM_CHECKOUT_PHASE', CHECKOUT_PHASE_INITIALIZE);

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
            $subclass->add_phase('CUSTOM_CHECKOUT_PHASE_TEST', 43, 1);

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## Set the phases and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases([CHECKOUT_PHASE_AUTHORIZE]);

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1);
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    };


    ## Set the phases using news' phases option and make sure they stick
    {
        my $checkout = $subclass->new({phases => [CHECKOUT_PHASE_DELIVER]});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1);
        is($phases->[0], CHECKOUT_PHASE_DELIVER);
    };


    ## check scalar/list context returns on phases default
    {
        my $checkout = $subclass->new;
        my @phases = $checkout->phases;
        ok(scalar @phases >= 1);

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        ok(scalar @{$phases} >= 1);
    };


    ## check scalar/list context returns on set phases
    {
        my $checkout = $subclass->new({phases => [CHECKOUT_PHASE_DELIVER, CHECKOUT_PHASE_INITIALIZE]});
        my @phases = $checkout->phases;
        is(scalar @phases, 2);

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2);
    };


    ## Set the phases using a string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1);
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
    };


    ## Set the phases using a comma seperated string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_DELIVER');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2);
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
        is($phases->[1], CHECKOUT_PHASE_DELIVER);
    };


    ## Set the phases using a space seperated string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE CHECKOUT_PHASE_DELIVER');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2);
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
        is($phases->[1], CHECKOUT_PHASE_DELIVER);
    };


    ## Set the phases using news' phases option as string and make sure they stick
    {
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_DELIVER'});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1);
        is($phases->[0], CHECKOUT_PHASE_DELIVER);
    };


    ## Set the phases using news' phases option as comma seperated string and make
    ## sure they stick
    {
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_AUTHORIZE,
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
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_AUTHORIZE
        CHECKOUT_PHASE_DELIVER'});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2);
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
        is($phases->[1], CHECKOUT_PHASE_DELIVER);
    };

};
