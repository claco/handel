#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

    use_ok('Handel::Storage::DBIC');
};


{
    my $connection = ['MyDSN', 'MyUser', 'Mypass', {}];

    my $storage = Handel::Storage::DBIC->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => $connection
    });
    isa_ok($storage, 'Handel::Storage');
    is_deeply($storage->connection_info, $connection, 'connection information was set');

    $storage->connection_info(undef);
    is($storage->connection_info, undef, 'connection info was unset');
};
