#!perl -wT
# $Id$
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

    is($storage->currency_class, 'Handel::Currency', 'set currenct class');

    ## throw exception when setting a bogus currency class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->currency_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/currency_class.*could not be loaded/i, 'could not be loaded in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    is($storage->currency_class, 'Handel::Currency', 'currency class still set');

    ok(!Class::Inspector->loaded('Handel::Base'), 'currency class not loaded');
    $storage->currency_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'), 'currency class loaded');

    $storage->currency_class(undef);
    is($storage->currency_class, undef, 'currency class unset');
};
