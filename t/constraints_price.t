#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 20;

    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Currency');
};

ok(!constraint_price('junk.foo'),   'alpha gibberish price');
ok(!constraint_price(undef),        'value is undefined');
ok(!constraint_price(''),           'value is empty string');
ok(!constraint_price(-14),          'negative number price');
ok(!constraint_price(-25.79),       'negative float price');
ok(constraint_price(0),             'zero price');
ok(constraint_price(0.00),          'zero float price');
ok(!constraint_price(345.345),      'overextended price float');
ok(!constraint_price(1234567.00),   'overextended price float');
ok(!constraint_price(1234567),      'overextended price int');
ok(constraint_price(25),            'positive int price');
ok(constraint_price(25.89),         'positive float price');
ok(constraint_price(100.00),        'positive float price');
ok(constraint_price(99999.99),      'positive float price');
ok(constraint_price('34.66'),       'positive float price string');
ok(constraint_price(Handel::Currency->new(1.23)), 'with a currency object');
ok(constraint_price(bless({value => 1.23}, 'CustomCurrency')), 'with a non-currency object');
ok(!constraint_price(bless({value => 'abc'}, 'CustomCurrency')), 'with a non-currency object');

package CustomCurrency;
use strict;
use warnings;
use overload
    '0+'     => sub {shift->value},
    'bool'   => sub {shift->value},
    '""'     => sub {shift->value},
    fallback => 1;

sub value {return shift->{'value'}};

1;