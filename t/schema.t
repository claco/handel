#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 48;

    use_ok('Handel::Schema');
};


## connect using args
{
    my $schema = Handel::Schema->connect(
        'mydsn', 'myuser', 'mypass', {RaiseError => 1}
    );
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'mydsn', 'dsn arg was set');
    is($connect_info->[1], 'myuser', 'user arg was set');
    is($connect_info->[2], 'mypass', 'password arg was set');
    is_deeply($connect_info->[3], {RaiseError => 1}, 'attributes arg was set');
};


## connect using newer ENV
{
    local $ENV{'HandelDBIDSN'} = 'myenvdsn';
    local $ENV{'HandelDBIUser'} = 'myenvuser';
    local $ENV{'HandelDBIPassword'} = 'myenvpass';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'myenvdsn', 'dsn ENV was set');
    is($connect_info->[1], 'myenvuser', 'user ENV was set');
    is($connect_info->[2], 'myenvpass', 'password ENV was set');
    is_deeply($connect_info->[3], {AutoCommit => 1}, 'attributes default was used');
};


## connect using older ENV
{
    local $ENV{'db_dsn'} = 'myoldenvdsn';
    local $ENV{'db_user'} = 'myoldenvuser';
    local $ENV{'db_pass'} = 'myoldenvpass';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'myoldenvdsn', 'dsn ENV was set');
    is($connect_info->[1], 'myoldenvuser', 'user ENV was set');
    is($connect_info->[2], 'myoldenvpass', 'password ENV was set');
    is_deeply($connect_info->[3], {AutoCommit => 1}, 'attributes default was used');
};


## create dsn from newer ENV
{
    local $ENV{'HandelDBIDriver'} = 'myenvdriver';
    local $ENV{'HandelDBIHost'} = 'myenvhost';
    local $ENV{'HandelDBIPort'} = 'myenvport';
    local $ENV{'HandelDBIName'} = 'myenvname';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'dbi:myenvdriver:dbname=myenvname;host=myenvhost;port=myenvport', 'dsn was created from ENV');
};


## create dsn from newer ENV without port
{
    local $ENV{'HandelDBIDriver'} = 'myenvdriver';
    local $ENV{'HandelDBIHost'} = 'myenvhost';
    local $ENV{'HandelDBIName'} = 'myenvname';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'dbi:myenvdriver:dbname=myenvname;host=myenvhost', 'dsn was created from ENV');
};


## create dsn from newer ENV without host
{
    local $ENV{'HandelDBIDriver'} = 'myenvdriver';
    local $ENV{'HandelDBIPort'} = 'myenvport';
    local $ENV{'HandelDBIName'} = 'myenvname';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'dbi:myenvdriver:dbname=myenvname', 'dsn was created from ENV');
};


## create dsn from older ENV
{
    local $ENV{'db_driver'} = 'myoldenvdriver';
    local $ENV{'db_host'} = 'myoldenvhost';
    local $ENV{'db_port'} = 'myoldenvport';
    local $ENV{'db_name'} = 'myoldenvname';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'dbi:myoldenvdriver:dbname=myoldenvname;host=myoldenvhost;port=myoldenvport', 'dsn was created from ENV');
};


## don't append host/port if you're passing a dsn
{
    local $ENV{'HandelDBIHost'} = 'myenvhost';
    local $ENV{'HandelDBIPort'} = 'myenvport';

    my $schema = Handel::Schema->connect('mydsn', 'myuser', 'mypass');
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], 'mydsn', 'dsn arg was set');
    is($connect_info->[1], 'myuser', 'user arg was set');
    is($connect_info->[2], 'mypass', 'password arg was set');
};


## connect with no connection information anywhere
{
    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], undef, 'dsn is still undef');
    is($connect_info->[1], undef, 'user is still undef');
    is($connect_info->[2], undef, 'password is still undef');
    is_deeply($connect_info->[3], {AutoCommit => 1}, 'attributes arg was set');
};


## must have both driver and database to create a dsn
{
    local $ENV{'HandelDBIDriver'} = 'mydriver';

    my $schema = Handel::Schema->connect;
    isa_ok($schema, 'Handel::Schema', 'connect returns a schema object');

    my $connect_info = $schema->storage->connect_info;
    isa_ok($connect_info, 'ARRAY', 'connect_info returns an array reference');

    is($connect_info->[0], undef, 'dsn is still undef');
    is($connect_info->[1], undef, 'user is still undef');
    is($connect_info->[2], undef, 'password is still undef');
    is_deeply($connect_info->[3], {AutoCommit => 1}, 'attributes arg was set');
};
