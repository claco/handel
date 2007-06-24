#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 45;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $default_values = {
        foo => 'bar',
        baz => 'quix'
    };

    my $validation_profile = [
        param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]
    ];

    my $constraints = {
        foo => {'check_foo' => sub{}},
        bar => {'check_bar' => sub{}}
    };

    my $add_columns = [qw/foo bar baz/];
    my $remove_columns = [qw/bar/];
    my $currency_columns = [qw/foo/];

    my $storage = Handel::Storage->new({
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        autoupdate         => 2,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns,
    });

    isa_ok($storage, 'Handel::Storage');

    ## iterator_class
    is($storage->iterator_class, 'Handel::Base', 'iterator class is set');
    is(Handel::Storage->iterator_class, 'Handel::Iterator::List', 'iterator class is set');

    ## currency_class
    is($storage->currency_class, 'Handel::Base', 'iterator class is set');
    is(Handel::Storage->currency_class, 'Handel::Currency', 'currency class is set');

    ## autoupdate
    is($storage->autoupdate, 2, 'autoupdate is set');
    is(Handel::Storage->autoupdate, 1, 'autoupdate is set');

    ## default_values
    is_deeply($storage->default_values, $default_values, 'defalt values are set');
    is(Handel::Storage->default_values, undef, 'default values are unset');

    ## validation_profile
    is_deeply($storage->validation_profile, $validation_profile, 'validation profile is set');
    is(Handel::Storage->validation_profile, undef, 'validaiton profile is unset');

    ## constraints
    is_deeply($storage->constraints, $constraints, 'constraints are set');
    is(Handel::Storage->constraints, undef, 'constraints are unset');

    ## add_columns
    is_deeply([$storage->columns], [qw/foo baz/], 'columns are set');
    is(Handel::Storage->columns, 0, 'columns are unset');

    ## currency_columns
    is_deeply([$storage->currency_columns], $currency_columns, 'currency columns are set');
    is(Handel::Storage->currency_columns, 0, 'currency columns are unset');
};


## check the virtuals
{
    foreach my $method (qw/add_item count_items create delete delete_items search search_items txn_begin txn_commit txn_rollback/) {
        try {
            local $ENV{'LANG'} = 'en';
            Handel::Storage->$method;
    
            fail('no exception thrown');
        } catch Handel::Exception::Virtual with {
            pass('caught virtual exception');
            like(shift, qr/virtual/i, 'virtual in message');
        } otherwise {
            fail('caught other exception');
        };
    };
};

## check virtuals on result
{
    my $result = bless {}, Handel::Storage->result_class;

    foreach my $method (qw/delete discard_changes update/) {
        try {
            local $ENV{'LANG'} = 'en';
            $result->$method;
    
            fail('no exception thrown');
        } catch Handel::Exception::Virtual with {
            pass('caught virtual exception');
            like(shift, qr/virtual/i, 'virtual in message');
        } otherwise {
            fail('caught other exception');
        };
    };
};
