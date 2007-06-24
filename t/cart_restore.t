#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 16;

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Cart');
&run('Handel::Subclassing::CartOnly');
&run('Handel::Subclassing::Cart');

sub run {
    my ($subclass) = @_;


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart subclass
    {
        try {
            local $ENV{'LANG'} = 'en';
            $subclass->restore(id => '1234');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'no a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart::Item subclass
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $fakeitem = bless {}, 'FakeItem';
            $subclass->restore($fakeitem);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/not a hash/i, 'no a hash ref in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };
};
