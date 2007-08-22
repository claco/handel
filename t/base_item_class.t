#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 9;
    use Class::Inspector;

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    is(Handel::Base->item_class, undef, 'item class is undefined');

    ## throw exception when setting a bogus item class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            Handel::Base->cart_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception with {
            pass('caught exception');
            like(shift, qr/cart_class.*could not be loaded/i, 'class not loaded in message');
        } otherwise {
            fail('other exception thrown');
        };
    };

    is(Handel::Base->item_class, undef, 'item class is unchanged');

    ok(!Class::Inspector->loaded('Handel::Cart::Item'), 'item class not loaded');
    Handel::Base->item_class('Handel::Cart::Item');
    ok(Class::Inspector->loaded('Handel::Cart::Item'), 'item class loaded');

    Handel::Base->item_class(undef);
    is(Handel::Base->item_class, undef, 'undefined item class');
};
