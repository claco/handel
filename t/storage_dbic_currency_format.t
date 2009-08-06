#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 17;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Items',
    currency_format  => 'FMT_NAME',
    currency_columns => [qw/price/],
    connection_info  => [
        Handel::Test->init_schema->dsn
    ]
});


my $item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->format, 'FMT_NAME', 'format was set');
is($item->price->stringify, '1.11 US Dollar', 'got long format name');



$storage->currency_format('FMT_HTML');
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->format, 'FMT_HTML', 'format was set');
is($item->price->stringify, '&#x0024;1.11', 'got html format');


$storage->currency_format(undef);
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->format, 'FMT_STANDARD', 'format is not set');
is($item->price->stringify, '1.11 USD', 'got short format');


{
    local $ENV{'HandelCurrencyFormat'} = 'FMT_NAME';
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->format, 'FMT_NAME', 'no format is set');
    is($item->price->stringify, '1.11 US Dollar', 'got long format');
};


{
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->format, 'FMT_STANDARD', 'no format is set');
    is($item->price->stringify, '1.11 USD', 'for short name format');
};
