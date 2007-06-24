#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 25;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## create a new storage and check configuration
    my $sub = sub{};
    my $storage = Handel::Storage->new({
        default_values     => {id => 1, name => 'New Cart'},
        validation_profile => {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]},
        add_columns        => [qw/one two/],
        remove_columns     => [qw/name/],
        constraints        => {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}},
        currency_columns   => [qw/one/]
    });
    isa_ok($storage, 'Handel::Storage');

    my $clone = $storage->clone;
    isa_ok($clone, 'Handel::Storage');
    
    is_deeply($clone, $storage, 'clone is like original');
    
    ## make them diverge
    $clone->iterator_class('Handel::Base');
    is($clone->iterator_class, 'Handel::Base', 'set clone iterator class');
    is($storage->iterator_class, 'Handel::Iterator::List', 'original iterator class unchanged');

    $clone->currency_class('Handel::Base');
    is($clone->currency_class, 'Handel::Base', 'set clone currency class');
    is($storage->currency_class, 'Handel::Currency', 'original currency class unchanged');
    
    $clone->autoupdate(3);
    is($clone->autoupdate, 3, 'set autoupdate in clone');
    is($storage->autoupdate, 1, 'original autoupdate is unchanged');

    $clone->default_values->{id} = 2;
    is_deeply($clone->default_values, {id => 2, name => 'New Cart'}, 'set clone default values');
    is_deeply($storage->default_values, {id => 1, name => 'New Cart'}, 'original default values unchanged');

    $clone->validation_profile->{'cart'} = [qw/foo/];
    is_deeply($clone->validation_profile, {cart=>['foo']}, 'set clone validaiton profile');
    is_deeply($storage->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]}, 'original validation profile unchanged');

    $clone->add_columns('quix');
    is_deeply($clone->_columns, [qw/one two quix/], 'set clone columns');
    is_deeply($storage->_columns, [qw/one two/], 'original columns unchanged');
    
    $clone->remove_columns('two');
    is_deeply($clone->_columns, [qw/one quix/], 'change clone columns');
    is_deeply($storage->_columns, [qw/one two/], 'original columns unchanged');
    
    my $foo = sub{};
    $clone->add_constraint('foo', 'check foo', $foo);
    is_deeply($clone->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub},
            foo  => {'check foo' => $foo}
    }, 'set clone constraints');
    is_deeply($storage->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}
    }, 'original constraints unchanged');

    push @{$clone->_currency_columns}, 'dongle';
    is_deeply([sort $clone->currency_columns], [qw/dongle one/], 'set clone currency columns');
    is_deeply([$storage->currency_columns], [qw/one/], 'original currency columns unchanged');

    undef $clone;

    ## throw exception as a class method
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage->clone;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/not a class/i, 'not a class in message');
        } otherwise {
            fail('other exception caught');
        };
    };
};
