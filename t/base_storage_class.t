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
    my $base = bless {}, 'Handel::Base';
    
    is($base->storage_class, 'Handel::Storage', 'storage class is set');
    
    ok(!Class::Inspector->loaded('Handel::Subclassing::Storage'), 'storage class not loaded');
    $base->storage_class('Handel::Subclassing::Storage');
    is($base->storage_class, 'Handel::Subclassing::Storage', 'storage class is set');
    ok(Class::Inspector->loaded('Handel::Subclassing::Storage'), 'storage class is loaded');

    ## throw exception when setting a bogus storage class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $base->storage_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('caught storage exception');
            like(shift, qr/storage_class.*could not be loaded/i, 'class not loaded in message');
        } otherwise {
            fail('cauht other exception');
        };
    };

    is($base->storage_class, 'Handel::Subclassing::Storage', 'storage class is unchanged');
    $base->storage_class(undef);
    is($base->storage_class, undef, 'undefined storae class');
};
