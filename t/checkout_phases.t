#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 159;

    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
};


## add a phase and import
{
    is(main->can('NEWPHASE'), undef, 'new phase does not exists');
    Handel::Checkout->add_phase('NEWPHASE', 23, 1);
    can_ok('main', 'NEWPHASE');
    is(&main::NEWPHASE, 23, 'new phase in place');
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
            local $ENV{'LANGUAGE'} = 'en';
            my $checkout = $subclass->new;

            $checkout->phases({'1234' => 1});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not an array/i, 'not array in message');
        } otherwise {
            fail('other exception caught');
        };
    };



    ## Check for Handel::Exception::Argument when we pass something other
    ## than an array reference in news' phases option
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $checkout = $subclass->new({phases => {'1234' => 1}});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not an array/i, 'not array in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## Test for Handel::Exception::Constraint if new constant name already exists
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->add_phase('CHECKOUT_PHASE_INITIALIZE', 99);

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/already exists/i, 'already exists in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## Test for Handel::Exception::Constraint if new constant value already exists
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->add_phase('CUSTOM_CHECKOUT_PHASE', CHECKOUT_PHASE_INITIALIZE);

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/already exists/i, 'already exists in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## Test for Handel::Exception::Constraint if new constant already exists in caller
    sub CUSTOM_CHECKOUT_PHASE_TEST {};
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $subclass->add_phase('CUSTOM_CHECKOUT_PHASE_TEST', 43, 1);

            fail('no exception thrown');
        } catch Handel::Exception::Constraint with {
            pass('caught constraint exception');
            like(shift, qr/already exists/i, 'already exists in message');
        } otherwise {
            fail('other exception caught');
        };
    };


    ## Set the phases and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases([CHECKOUT_PHASE_AUTHORIZE]);

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1, 'has 1 phase');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
    };


    ## Set the phases and make sure they stick as string
    {
        my $checkout = $subclass->new;

        $checkout->phases(['CHECKOUT_PHASE_AUTHORIZE']);

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1, 'has 1 phase');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
    };


    ## Set the phases using news' phases option and make sure they stick
    {
        my $checkout = $subclass->new({phases => [CHECKOUT_PHASE_DELIVER]});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1, 'has 1 phase');
        is($phases->[0], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };


    ## check scalar/list context returns on phases default
    {
        my $checkout = $subclass->new;
        my @phases = $checkout->phases;
        ok(scalar @phases >= 1, 'has phases');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        ok(scalar @{$phases} >= 1, 'has more than one phase');
    };


    ## check scalar/list context returns on set phases
    {
        my $checkout = $subclass->new({phases => [CHECKOUT_PHASE_DELIVER, CHECKOUT_PHASE_INITIALIZE]});
        my @phases = $checkout->phases;
        is(scalar @phases, 2, 'has 2 phases');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
    };


    ## check scalar/list context returns on set phases
    {
        my $checkout = $subclass->new({phases => ['CHECKOUT_PHASE_DELIVER', 'CHECKOUT_PHASE_INITIALIZE']});
        my @phases = $checkout->phases;
        is(scalar @phases, 2, 'has 2 phases');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
    };


    ## Set the phases using a string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1, 'has 1 phase');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
    };


    ## Set the phases using a comma seperated string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_DELIVER');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
        is($phases->[1], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };


    ## Set the phases using a space seperated string and make sure they stick
    {
        my $checkout = $subclass->new;

        $checkout->phases('CHECKOUT_PHASE_AUTHORIZE CHECKOUT_PHASE_DELIVER');

        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
        is($phases->[1], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };


    ## Set the phases using news' phases option as string and make sure they stick
    {
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_DELIVER'});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 1, 'has 1 phase');
        is($phases->[0], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };


    ## Set the phases using news' phases option as comma seperated string and make
    ## sure they stick
    {
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_AUTHORIZE, CHECKOUT_PHASE_DELIVER'});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
        is($phases->[1], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };


    ## Set the phases using news' space option as comma seperated string and make
    ## sure they stick
    {
        my $checkout = $subclass->new({phases => 'CHECKOUT_PHASE_AUTHORIZE CHECKOUT_PHASE_DELIVER'});
        my $phases = $checkout->phases;
        isa_ok($phases, 'ARRAY');
        is(scalar @{$phases}, 2, 'has 2 phases');
        is($phases->[0], CHECKOUT_PHASE_AUTHORIZE, 'authorize set');
        is($phases->[1], CHECKOUT_PHASE_DELIVER, 'deliver set');
    };

};
