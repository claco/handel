#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 10;
    use Class::Inspector;

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage::DBIC->new();
    isa_ok($storage, 'Handel::Storage::DBIC');

    is($storage->schema_class, undef, 'schema class is undefined');

    ## throw exception when setting a bogus schema class
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            $storage->schema_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass('storage exception caught');
            like(shift, qr/schema_class.*could not be loaded/i, 'schema class in message');
        } otherwise {
            fail('other exception caught');
        };
    };

    is($storage->schema_class, undef, 'schema class is still undefined');

    ok(!Class::Inspector->loaded('Handel::Base'), 'schema class is not loaded');
    $storage->schema_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'), 'schema class is now loaded');

    $storage->schema_class(undef);
    is($storage->schema_class, undef, 'schema class was unset');
};
