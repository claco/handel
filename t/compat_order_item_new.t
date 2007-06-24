#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 41;
    };

    use_ok('Handel::Order::Item');
    use_ok('Handel::Subclassing::OrderItem');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');

    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderItem', 2);

sub run {
    my ($subclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    {
        no strict 'refs';
        unshift @{"$subclass\:\:ISA"}, 'Handel::Compat' unless $subclass->isa('Handel::Compat');
        $subclass->storage->currency_class('Handel::Compat::Currency');
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $item = Handel::Order::Item->new(sku => 'FOO');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## create a new order item object
    {
        my $data = {
            sku         => 'sku1234',
            price       => 1.23,
            quantity    => 2,
            description => 'My SKU',
            total       => 2.46,
            orderid     => '00000000-0000-0000-0000-000000000000'
        };
        if ($subclass ne 'Handel::Order::Item') {
            $data->{'custom'} = 'custom';
        };

        my $item = $subclass->new($data);
        isa_ok($item, 'Handel::Order::Item');
        isa_ok($item, $subclass);
        ok(constraint_uuid($item->id));
        is($item->sku, 'sku1234');
        is($item->price, 1.23);
        is($item->quantity, 2);
        is($item->description, 'My SKU');
        is($item->total, 2.46);
        if ($subclass ne 'Handel::Order::Item') {
            is($item->custom, 'custom');
        };

        eval 'use Locale::Currency::Format';
        if ($@) {
            is($item->price->format, 1.23);
            is($item->price->format('CAD'), 1.23);
            is($item->price->format(undef, 'FMT_NAME'), 1.23);
            is($item->price->format('CAD', 'FMT_NAME'), 1.23);
            is($item->total->format, 2.46);
            is($item->total->format('CAD'), 2.46);
            is($item->total->format(undef, 'FMT_NAME'), 2.46);
            is($item->total->format('CAD', 'FMT_NAME'), 2.46);
        } else {
            is($item->price->format, '1.23 USD');
            is($item->price->format('CAD'), '1.23 CAD');
            is($item->price->format(undef, 'FMT_NAME'), '1.23 US Dollar');
            is($item->price->format('CAD', 'FMT_NAME'), '1.23 Canadian Dollar');
            is($item->total->format, '2.46 USD');
            is($item->total->format('CAD'), '2.46 CAD');
            is($item->total->format(undef, 'FMT_NAME'), '2.46 US Dollar');
            is($item->total->format('CAD', 'FMT_NAME'), '2.46 Canadian Dollar');
        };
    };

};
