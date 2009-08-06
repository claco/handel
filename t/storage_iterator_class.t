#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 10;
    use Class::Inspector;

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage->new();
    isa_ok($storage, 'Handel::Storage');

    is($storage->iterator_class, 'Handel::Iterator::List', 'set iterator class');

    ## throw exception when setting a bogus iterator class
    {
        try {
            $storage->iterator_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/iterator_class.*could not be loaded/i, 'could not be loaded in message');
        } otherwise {
            fail('caught other exception');
        };
    };

    is($storage->iterator_class, 'Handel::Iterator::List', 'iterator class unchanged');

    ok(!Class::Inspector->loaded('Handel::Base'), 'iterator class not loaded');
    $storage->iterator_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'), 'iterator class loaded');

    $storage->iterator_class(undef);
    is($storage->iterator_class, undef, 'iterator class unset');
};
