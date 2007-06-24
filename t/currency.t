#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 142;
    use Scalar::Util qw/refaddr/;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        Test::MockObject->fake_module('Finance::Currency::Convert::WebserviceX' => (
            new => sub {return bless {}, shift},
            convert => sub {return $_[1]+1.00}
        ));
    };

    use_ok('Handel::Currency');
    use_ok('Handel::Exception', ':try');
};


## create with no value
{
    my $currency = Handel::Currency->new;
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 0, 'value was set');
    is($currency->stringify, '0.00 USD', 'stringify to format');
    is($currency->code, 'USD', 'code is default');
    is($currency->format, 'FMT_STANDARD', 'format is default');
    is($currency->converter, undef, 'converter no defined');
};


## create new with no options
{
    my $currency = Handel::Currency->new(1.23);
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '1.23 USD', 'stringify to value');
    is($currency->code, 'USD', 'code is default');
    is($currency->format, 'FMT_STANDARD', 'format is default');
    is($currency->converter, undef, 'converter no defined');
};


## create new with code/format
{
    my $currency = Handel::Currency->new(1.23, 'CAD', 'FMT_COMMON');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '$1.23', 'stringify to value');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 'FMT_COMMON', 'format was set');
    is($currency->converter, undef, 'converter no defined');
};


## throw exception when bad currency code is set in new
{
    try {
        local $ENV{'LANG'} = 'en';
        my $currency = Handel::Currency->new(1.23, 'BAD');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## create and set code
{
    my $currency = Handel::Currency->new(1.23);
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '1.23 USD', 'stringify to value');
    is($currency->code, 'USD', 'code not set');
    is($currency->format, 'FMT_STANDARD', 'code not set');
    is($currency->converter, undef, 'converter no defined');

    $currency->code('USD');
    is($currency->code, 'USD', 'code set');
};


## throw exception when bad currency code is set
{
    my $currency = Handel::Currency->new(1.23);

    try {
        local $ENV{'LANG'} = 'en';

        $currency->code('BAD');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when bad currency code is set in ENV and pulled into format
{
    my $currency = Handel::Currency->new(1.23);

    try {
        local $ENV{'LANG'} = 'en';
        local $ENV{'HandelCurrencyCode'} = 'BAD';

        $currency->stringify;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        my $E = shift;
        diag $E;
        diag ref $E;
        fail('Other exception thrown');
    };
};


## throw exception when bad currency code is set in Defaults and pulled into format
{
    my $currency = Handel::Currency->new(1.23);

    try {
        local $ENV{'LANG'} = 'en';
        local $ENV{'HandelCurrencyCode'} = '';
        local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyCode'} = 'BAD';

        $currency->stringify;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when no code is set during format
{
    my $currency = Handel::Currency->new(1.23);

    try {
        local $ENV{'LANG'} = 'en';
        local $ENV{'HandelCurrencyCode'} = '';
        local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyCode'} = '';

        $currency->stringify;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## format using stock default
{
    local $ENV{'HandelCurrencyFormat'} = '';

    my $currency = Handel::Currency->new(1.23, 'CAD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '1.23 CAD', 'stringify to default');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 'FMT_STANDARD', 'format is not set');
    is($currency->converter, undef, 'converter not defined');
};


## format using altered default
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = 'FMT_SYMBOL';

    my $currency = Handel::Currency->new(1.23, 'CAD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '$1.23', 'stringify to value');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 'FMT_SYMBOL', 'format is not set');
    is($currency->converter, undef, 'converter not defined');
};


## format using object format
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = 'FMT_SYMBOL';

    my $currency = Handel::Currency->new(1.23, 'CAD', 'FMT_HTML');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '&#x0024;1.23', 'got object default format');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 'FMT_HTML', 'format was set');
    is($currency->converter, undef, 'converter not defined');
};


## format using object format as value instead of string
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = 'FMT_SYMBOL';

    my $currency = Handel::Currency->new(1.23, 'CAD', 0x0010);
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '&#x0024;1.23', 'got object default format');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 0x0010, 'format was set');
    is($currency->converter, undef, 'converter not defined');
};


## format using format param
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = 'FMT_SYMBOL';

    my $currency = Handel::Currency->new(1.23, 'CAD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify('FMT_HTML'), '&#x0024;1.23', 'got param format');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, 'FMT_SYMBOL', 'format is not set');
    is($currency->converter, undef, 'converter not defined');
};


## format using format param as value instead of string
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = 'FMT_SYMBOL';

    my $currency = Handel::Currency->new(1.23, 'CAD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify(0x0010), '&#x0024;1.23', 'got param format');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format,'FMT_SYMBOL', 'format is not set');
    is($currency->converter, undef, 'converter not defined');
};


## format using no format (Local::Currency::Format defaults)
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = '';

    my $currency = Handel::Currency->new(1.23, 'CAD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->value, 1.23, 'value was set');
    is($currency->stringify, '$1.23', 'got object default format');
    is($currency->code, 'CAD', 'code was set');
    is($currency->format, undef, 'format is not set');
    is($currency->converter, undef, 'converter not defined');
};


## get name
{
    local $ENV{'HandelCurrencyFormat'} = '';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyFormat'} = '';

    my $currency = Handel::Currency->new(1.23, 'USD');
    isa_ok($currency, 'Handel::Currency');
    is($currency->code, 'USD', 'code was set');
    is($currency->name, 'US Dollar', 'got name');
};


## get name with code from ENV
{
    local $ENV{'HandelCurrencyCode'} = 'USD';
    local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyCode'} = '';

    my $currency = Handel::Currency->new(1.23);
    isa_ok($currency, 'Handel::Currency');
    is($currency->code, 'USD', 'code is not set');
    is($currency->name, 'US Dollar', 'got name');
};


## throw exception when code is set for name
{
    my $currency = Handel::Currency->new(1.23);

    try {
        local $ENV{'LANG'} = 'en';
        local $ENV{'HandelCurrencyCode'} = '';
        local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyCode'} = '';

        $currency->name;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/currency code/i, 'currency code in message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when converter_class can't be loaded
{
    try {
        local $ENV{'LANG'} = 'en';
        Handel::Currency->converter_class('Bogus');

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Exception thrown');
        like(shift, qr/bogus could not be loaded/i, 'class not loaded in message');
    } otherwise {
        my $E = shift;
        diag $E;
        diag ref $E;
        fail('Other exception thrown');
    };
};


## test convert
SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 46 if $@;


    ## convert with code
    {
        my $currency = Handel::Currency->new(1.23, 'USD');
        isa_ok($currency, 'Handel::Currency');
        is($currency->value, 1.23, 'value was set');
        is($currency->stringify, '1.23 USD', 'stringify to value');
        is($currency->code, 'USD', 'code is set');
        is($currency->format, 'FMT_STANDARD', 'format is not set');
        is($currency->converter, undef, 'converter not defined');

        my $converted = $currency->convert('CAD');
        isa_ok($currency->converter, 'Finance::Currency::Convert::WebserviceX');
        isa_ok($converted, 'Handel::Currency');
        is($converted->value, 2.23, 'value was set');
        is($converted->stringify, '2.23 CAD', 'stringify to value');
        is($converted->code, 'CAD', 'code is set');
        is($converted->format, 'FMT_STANDARD', 'format is not set');
    };


    ## convert with code using ENV
    {
        local $ENV{'HandelCurrencyCode'} = 'USD';

        my $currency = Handel::Currency->new(1.23);
        isa_ok($currency, 'Handel::Currency');
        is($currency->value, 1.23, 'value was set');
        is($currency->stringify, '1.23 USD', 'stringify to value');
        is($currency->code, 'USD', 'code is not set');
        is($currency->format, 'FMT_STANDARD', 'format is not set');
        is($currency->converter, undef, 'converter not defined');

        my $converted = $currency->convert('CAD');
        isa_ok($currency->converter, 'Finance::Currency::Convert::WebserviceX');
        isa_ok($converted, 'Handel::Currency');
        is($converted->value, 2.23, 'value was set');
        is($converted->stringify, '2.23 CAD', 'stringify to value');
        is($converted->code, 'CAD', 'code is set');
        is($converted->format, 'FMT_STANDARD', 'format is not set');
    };


    ## test when converter returns nothing
    {
        Test::MockObject->fake_module('Finance::Currency::Convert::WebserviceX' => (
            new => sub {return bless {}, shift},
            convert => sub {}
        ));

        my $currency = Handel::Currency->new(1.23, 'USD');
        my $converted = $currency->convert('CAD');
        isa_ok($converted, 'Handel::Currency');
        is($converted->value, 0, 'value is 0 when converter fails');
        is($converted->stringify, '0.00 CAD', 'stringify to value');
        is($converted->code, 'CAD', 'code is set');
        is($converted->format, 'FMT_STANDARD', 'format is not set');
    };


    ## throw exception when no code is set during convert
    {
        my $currency = Handel::Currency->new(1.23);

        try {
            local $ENV{'LANG'} = 'en';
            local $ENV{'HandelCurrencyCode'} = '';
            local $Handel::ConfigReader::DEFAULTS{'HandelCurrencyCode'} = '';

            $currency->convert('CAD');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/currency code/i, 'currency code in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## throw exception when no code is passed to convert
    {
        my $currency = Handel::Currency->new(1.23, 'USD');

        try {
            local $ENV{'LANG'} = 'en';

            $currency->convert;

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/currency code/i, 'currency code in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## throw exception when bad code is returned from code into convert
    {
        my $currency = Handel::Currency->new(1.23, 'USD');

        try {
            local $ENV{'LANG'} = 'en';

            no warnings 'redefine';
            local *Handel::Currency::code = sub {
                return 'BOGUS';
            };
            
            $currency->convert('CAD');

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('Argument exception thrown');
            like(shift, qr/currency code/i, 'currency code in message');
        } otherwise {
            fail('Other exception thrown');
        };
    };


    ## return self if to is same as from
    {
        my $currency = Handel::Currency->new(1.23, 'USD');
        isa_ok($currency, 'Handel::Currency');
        is($currency->value, 1.23, 'value was set');
        is($currency->stringify, '1.23 USD', 'stringify to value');
        is($currency->code, 'USD', 'code is set');
        is($currency->format, 'FMT_STANDARD', 'format is not set');
        is($currency->converter, undef, 'converter not defined');

        my $converted = $currency->convert('USD');
        is($currency->converter, undef, 'converter not defined');
        is(refaddr $converted, refaddr $currency, 'return self if codes are the same');
        isa_ok($converted, 'Handel::Currency');
        is($converted->value, 1.23, 'value was set');
        is($converted->stringify, '1.23 USD', 'stringify to value');
        is($converted->code, 'USD', 'code is set');
        is($converted->format, 'FMT_STANDARD', 'format is not set');
    };
};


## test loading of utf8
{
    local $] = 5.007999;

    my $currency = Handel::Currency->new(1.23);
    isa_ok($currency, 'Handel::Currency');
    is($currency->stringify, '1.23 USD', 'still got format');
};


## set converter_class to nothing, and put it back
{
    Handel::Currency->converter_class(undef);
    is(Handel::Currency->converter_class, 'Finance::Currency::Convert::WebserviceX', 'unset converter_class');

    Handel::Currency->converter_class('Handel::Base');
    is(Handel::Currency->converter_class, 'Handel::Base', 'set converter_class');

    Handel::Currency->converter_class('CustomConverterClass');
    is(Handel::Currency->converter_class, 'CustomConverterClass', 'set converter_class');
};


package CustomConverterClass;
use strict;
use warnings;

BEGIN {
    use base qw/Finance::Currency::Convert::WebserviceX/;
};
1;