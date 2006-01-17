#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 10;
    };

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
            $subclass->restore(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart::Item subclass
    {
        try {
            my $fakeitem = bless {}, 'FakeItem';
            $subclass->restore($fakeitem);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };

};
