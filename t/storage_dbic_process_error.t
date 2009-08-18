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
        plan tests => 16;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::L10N', qw(translate));
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## pass an exception object right on through
try {
    local $ENV{'LANGUAGE'} = 'en';
    Handel::Storage::DBIC->process_error(Handel::Exception->new);

    fail('no exception thrown');
} catch Handel::Exception with {
    my $e = shift;
    isa_ok($e, 'Handel::Exception');
    like($e, qr/unspecified error/i, 'unspecified in message');
} otherwise {
    fail('other exception caught');
};


## catch 'is not unique' DBIC errors
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->schema_instance->resultset($storage->schema_source)->create({
        id      => '11111111-1111-1111-1111-111111111111',
        shopper => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass('caught constraint exception');
    like(shift, qr/id value already exists/i, 'value exists in message');
} otherwise {
    fail('other exception caught');
};

## catch 'are not unique' DBIC errors
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->process_error('DBD::SQLite::st execute failed: columns col1, col2 are not unique');

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass('caught constraint exception');
    cmp_ok(shift->text, 'eq', translate('COLUMN_VALUE_EXISTS', "col1, col2"), 'check COLUMN_VALUE_EXISTS message');
} otherwise {
    fail('other exception caught');
};


## catch 'value already exists' DBIC errors
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->process_error('id value already exists');

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass('caught constraint exception');
    like(shift, qr/id value already exists/i, 'value exists in message');
} otherwise {
    fail('other exception caught');
};


## catch other DBIC errors
try {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->schema_instance->resultset('Foo')->create({
        id => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/can\'t find source/i, 'source in massage');
} otherwise {
    fail('other exception caught');
};


## catch other blessed objects
my $message = 'Custom Foo';
my $error = bless(\$message, 'Foo');

eval {
    local $ENV{'LANGUAGE'} = 'en';
    $storage->process_error($error);
};
if ($@) {
    pass('caught custom exception');
    isa_ok($@, 'Handel::Exception::Storage');
    like($@->text, qr/Custom Foo/i, 'custom massage');
} else {
    fail('no exception caught');   
};


package Foo;
use strict;
use warnings;

use overload
    '""' => sub {my $self = shift; return ${$self}},
    fallback => 1;

1;
