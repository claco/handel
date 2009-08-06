#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 22;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## setup a schema
    my $storage = Handel::Storage->new({
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        autoupdate         => 2,
        default_values     => {foo => 'bar',baz => 'quix'},
        validation_profile => [param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]],
        add_columns        => [qw/foo bar baz/],
        remove_columns     => [qw/quix temp/],
        constraints        => {
            foo => {'check_foo' => sub{}},
            bar => {'check_bar' => sub{}}
        },
        currency_columns   => [qw/foo bar/]
    });

    isa_ok($storage, 'Handel::Storage');

    ## now call setup again and make sure it overides the old
    my $default_values = {
        foo => 'new',
        baz => 'old'
    };

    my $validation_profile = [
        param1 => [ ['BLANK'], ['ASCII', 2, 12] ]
    ];

    my $constraints = {
        one => sub{},
        two => sub{}
    };

    my $currency_columns = [qw/baz/];
    my $add_columns = [qw/one two three/];
    my $remove_columns = [qw/this that/];

    $storage->setup({
        iterator_class     => 'Handel::Iterator',
        currency_class     => 'Handel::Currency',
        autoupdate         => 3,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns,
        _does_not_exist    => 'Boo!'
    });

    is($storage->{'_does_not_exist'}, 'Boo!');

    ## iterator_class
    is($storage->iterator_class, 'Handel::Iterator', 'iterator class is set');
    is(Handel::Storage->iterator_class, 'Handel::Iterator::List', 'iterator class is set');

    ## currency_class
    is($storage->currency_class, 'Handel::Currency', 'iterator class is set');
    is(Handel::Storage->currency_class, 'Handel::Currency', 'iterator class is set');

    ## autoupdate
    is($storage->autoupdate, 3, 'autoupdate is set');
    is(Handel::Storage->autoupdate, 1, 'autoupdate is set');

    ## default_values
    is_deeply($storage->default_values, $default_values, 'default values are set');
    is(Handel::Storage->default_values, undef, 'default values are unset');

    ## validation_profile
    is_deeply($storage->validation_profile, $validation_profile, 'validation profile is set');
    is(Handel::Storage->validation_profile, undef, 'validation profile is unset');

    ## constraints
    is_deeply($storage->constraints, $constraints, 'constraints were set');
    is(Handel::Storage->constraints, undef, 'constraints are unset');

    ## add_columns
    is_deeply([sort $storage->columns], [qw/bar baz foo one three two/], 'columns are set');
    is(Handel::Storage->columns, 0, 'no columns are set');

    ## currency_columns
    is_deeply([$storage->currency_columns], $currency_columns, 'currency columns are set');
    is(Handel::Storage->currency_columns, 0, 'no currency columns are set');


    ## throw exception if setup gets no $args
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $storage = Handel::Storage->new;
            $storage->setup();

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not a HASH/i, 'not a hash in message');
        } otherwise {
            fail('caught other exception');
        };
    };
};
