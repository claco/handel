#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Handel::Currency');
};

## test stringification
{
    my $currency = Handel::Currency->new(1.2);
    isa_ok($currency, 'Handel::Currency');
    is($currency, 1.2);


    eval 'use Locale::Currency::Format';
    if ($@) {
        is($currency->format, 1.2);
        is($currency->format('CAD'), 1.2);
        is($currency->format(undef, 'FMT_NAME'), 1.2);
        is($currency->format('CAD', 'FMT_NAME'), 1.2);
    } else {
        is($currency->format, '1.20 USD');
        is($currency->format('CAD'), '1.20 CAD');
        is($currency->format(undef, 'FMT_NAME'), '1.20 US Dollar');
        is($currency->format('CAD', 'FMT_NAME'), '1.20 Canadian Dollar');
    };
};
