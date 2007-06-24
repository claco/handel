#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 7;

    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

$storage->_columns([qw/foo bar baz/]);

ok($storage->has_column('bar'), 'has bar column');
ok(!$storage->has_column('quix'), 'does not have quix column');

my $storage_result = bless {}, 'StorageResult';
my $result = $storage->result_class->create_instance($storage_result, $storage);
isa_ok($result, 'Handel::Storage::Result');
ok($result->has_column('foo'), 'has foo column');
ok(!$result->has_column('bar'), 'has no bar column');

package StorageResult;

sub foo {};

1;
