#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 10;
    use Class::Inspector;

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    is(Handel::Base->cart_class, undef, 'cart_class is undef');

    ## throw exception when setting a bogus cart class
    {
        try {
            Handel::Base->cart_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception with {
            pass('caught Handel::Exception');
            like(shift, qr/cart_class.*could not be loaded/i, 'class not loaded in message');
        } otherwise {
            fail('failed to catch Handel::Exception');
        };
    };

    is(Handel::Base->cart_class, undef, 'cart_class is still undefined');

    ok(!Class::Inspector->loaded('Handel::Cart'), 'Handel::Cart is not loaded');
    Handel::Base->cart_class('Handel::Cart');
    is(Handel::Base->cart_class, 'Handel::Cart', 'cart_class is Handel::Cart');
    ok(Class::Inspector->loaded('Handel::Cart'), 'Handel::Cart is loaded');

    Handel::Base->cart_class(undef);
    is(Handel::Base->cart_class, undef, 'cart_class is undef');
};
