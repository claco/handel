# $Id$
package Handel::Test;
use strict;
use warnings;

BEGIN {
    # little trick by Ovid to pretend to subclass+exporter Test::More
    use base qw/Test::Builder::Module Class::Accessor::Grouped/;
    use Test::More;
    use File::Spec::Functions qw/catfile catdir/;

    @Handel::Test::EXPORT = @Test::More::EXPORT;

    __PACKAGE__->mk_group_accessors('inherited', qw/db_dir db_file/);
};

__PACKAGE__->db_dir(catdir('t', 'var'));
__PACKAGE__->db_file('handel.db');

## cribbed and modified from DBICTest in DBIx::Class tests
sub init_schema {
    my ($self, %args) = @_;
    my $db_dir  = $args{'db_dir'}  || $self->db_dir;
    my $db_file = $args{'db_file'} || $self->db_file;
    my $namespace = $args{'namespace'} || 'Handel::TestSchema';
    my $db = catfile($db_dir, $db_file);

    eval 'use DBD::SQLite';
    if ($@) {
       BAIL_OUT('DBD::SQLite not installed');

        return;
    };

    eval 'use Handel::Test::Schema';
    if ($@) {
        BAIL_OUT("Could not load Handel::Test:Schema: $@");

        return;
    };

    unlink($db) if -e $db;
    unlink($db . '-journal') if -e $db . '-journal';
    mkdir($db_dir) unless -d $db_dir;

    my $dsn = 'dbi:SQLite:' . $db;
    my $schema = Handel::Test::Schema->compose_namespace($namespace)->connect($dsn, undef, undef, {AutoCommit => 1});
    $schema->storage->on_connect_do([
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY'
    ]);

    foreach my $source ($schema->sources) {
        $schema->source($source)->add_column('custom' => {
            data_type   => 'varchar',
            size        => 50,
            is_nullable => 1
        });
    };

    __PACKAGE__->deploy_schema($schema, %args);
    __PACKAGE__->populate_schema($schema, %args) unless $args{'no_populate'};

    return $schema;
};

sub deploy_schema {
    my ($self, $schema, %options) = @_;
    my $eval = $options{'eval_deploy'};

    eval 'use SQL::Translator';
    if (!$@ && !$options{'no_deploy'}) {
        eval {
            $schema->deploy();
        };
        if ($@ && !$eval) {
            die $@;
        };
    } else {
        open IN, catfile('t', 'sql', 'test.sqlite.sql');
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        eval {
            ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
        };
        if ($@ && !$eval) {
            die $@;
        };
    };
};

sub clear_schema {
    my ($self, $schema, %options) = @_;

    foreach my $source ($schema->sources) {
        $schema->resultset($source)->delete_all;
    };
};

sub populate_schema {
    my ($self, $schema, %options) = @_;

    if ($options{'clear'}) {
        $self->clear_schema($schema, %options);
    };

    if (!$options{'no_cart'}) {
        $schema->populate('Carts', [
            [ qw/id shopper type name description custom/ ],
            ['11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',0,'Cart 1', 'Test Temp Cart 1', 'custom'],
            ['22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111',0,'Cart 2', 'Test Temp Cart 2', 'custom'],
            ['33333333-3333-3333-3333-333333333333','33333333-3333-3333-3333-333333333333',1,'Cart 3', 'Saved Cart 1', 'custom']
        ]);

        $schema->populate('CartItems', [
            [ qw/id cart sku quantity price description custom/ ],
            ['11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111','SKU1111',1,1.11,'Line Item SKU 1', 'custom'],
            ['22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111','SKU2222',2,2.22,'Line Item SKU 2', 'custom'],
            ['33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222','SKU3333',3,3.33,'Line Item SKU 3', 'custom'],
            ['44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333','SKU4444',4,4.44,'Line Item SKU 4', 'custom'],
            ['55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333','SKU1111',5,5.55,'Line Item SKU 5', 'custom']
        ]);
    };

    if (!$options{'no_order'}) {
        $schema->populate('Orders', [
            [ qw/id shopper type billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3 billtocity billtostate billtozip billtocountry billtodayphone billtonightphone billtofax billtoemail comments created handling number shipmethod shipping shiptosameasbillto shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3 shiptocity shiptostate shiptozip shiptocountry shiptodayphone shiptonightphone shiptofax shiptoemail subtotal total updated tax custom/ ],
            ['11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',0,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom'],
            ['22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111',1,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom'],
            ['33333333-3333-3333-3333-333333333333','33333333-3333-3333-3333-333333333333',1,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom']
        ]);

        $schema->populate('OrderItems', [
            [ qw/id orderid sku quantity price total description custom/ ],
            ['11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111','SKU1111',1,1.11,0,'Line Item SKU 1', 'custom'],
            ['22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111','SKU2222',2,2.22,0,'Line Item SKU 2', 'custom'],
            ['33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222','SKU3333',3,3.33,0,'Line Item SKU 3', 'custom'],
            ['44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333','SKU4444',4,4.44,0,'Line Item SKU 4', 'custom'],
            ['55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333','SKU1111',5,5.55,0,'Line Item SKU 5', 'custom']
        ]);
    };
};

1;
