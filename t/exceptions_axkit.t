#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 5;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        Test::MockObject->fake_module('Apache::AxKit::Exception');
    };

    use_ok('Handel::Exception', qw(:try));
};


SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 4 if $@;

    try {
        local $ENV{'LANGUAGE'} = 'en';
        throw Handel::Exception;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('caught exception');
        like($_[0]->text, qr/unspecified/, 'unhandled exception in message');
        is($_[0]->details, undef, 'details not set');
        isa_ok($_[0], 'Apache::AxKit::Exception');
    } otherwise {
        fail('Other exception thrown');
    };
};
