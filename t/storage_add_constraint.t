#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 14;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage->new;
    isa_ok($storage, 'Handel::Storage');
    is($storage->constraints, undef, 'no constraints defined');

    my $constraint = sub{};
    $storage->add_constraint('id', 'check id' => $constraint);
    is_deeply($storage->constraints, {id => {'check id' => $constraint}}, 'added constraints');

    my $new_constraint = sub{};
    $storage->add_constraint('name', 'first' => $new_constraint);
    $storage->add_constraint('name', 'second' => $new_constraint);


    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}, 'name' => {'first' => $new_constraint, 'second' => $new_constraint}}, 'appended constraints');

    ## throw exception when no column is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->add_constraint(undef, second => sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/no column/i, 'no column in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    ## throw exception when no name is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->add_constraint('id', undef, sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/no constraint name/i, 'no constraint name in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    ## throw exception when no constraint is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->add_constraint('id', 'second' => undef);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/no constraint/i, 'no constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    ## throw exception when non-CODEREF is passed
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->add_constraint('id', 'second' => []);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/no constraint/i, 'no constraint in message');
        } otherwise {
            fail('caught other exception');
        };
    };
};
