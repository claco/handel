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
        plan tests => 10;
    };

    use_ok('Handel::Storage::DBIC::Cart');
};

my $storage = Handel::Storage::DBIC::Cart->new;
isa_ok($storage, 'Handel::Storage::DBIC::Cart');

ok($storage->has_column('name'), 'has name column');
ok(!$storage->has_column('quix'), 'does not have quix column');

my $schema = $storage->schema_instance;
ok($storage->has_column('name'), 'has name column');
ok(!$storage->has_column('quix'), 'does not have quix column');

## cheat, and make sure it uses result source
$schema->source('Carts')->add_column('quix');
ok($storage->has_column('quix'), 'has quix column');


## chekc the results too
$storage->schema_instance(undef);
$storage->connection_info([Handel::Test->init_schema->dsn]);
my $result = $storage->search->first;
isa_ok($result, 'Handel::Storage::DBIC::Result');
ok($result->has_column('name'), 'has name column');
ok(!$result->has_column('foo'), 'has no foo column');
