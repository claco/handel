#!perl -w
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

    eval 'use Test::Spelling 0.11';
    plan skip_all => 'Test::Spelling 0.11 not installed' if $@;
};

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
createdb
behaviour
handel
rethrows
CVS
Candian
AxKit
CMS
CPAN
DBI
Intershop
TT
Taglib
Toolkit
ToolKit
ecommerce
PerlSetVar
SQL
dsn
uuid
WebGUI
XSP
AutoCommit
addpluginpaths
loadplugins
autoupdates
ignoreplugins
namespaces
plugins
ithreads
taglib
taglibs
uuids
wiki
modelclass
checkoutcontroller
CartModel
OrderModel
ordermodel
ordercontroller
cartmodel
cartcontroller
http
namespace
htaccess
API
sku
conf
guid
DBD
HandelAddPluginPaths
HandelCurrencyCode
HandelCurrencyFormat
HandelDBIDSN
HandelDBIDriver
HandelDBIHost
HandelDBIName
HandelDBIPassword
HandelDBIPort
HandelDBIUser
HandelIgnorePlugins
HandelLoadPlugins
HandelMaxQuantity
HandelMaxQuantityAction
HandelPluginPaths
billtoaddress
billtocity
billtocountry
billtodayphone
billtoemail
billtofax
billtofirstname
billtolastname
billtonightphone
billtostate
billtozip
params
shipmethod
shiptoaddress
shiptocity
shiptocountry
shiptodayphone
shiptoemail
shiptofax
shiptofirstname
shiptolastname
shiptonightphone
shiptosameasbillto
shiptostate
shiptozip
cartmode
ok
propertyname
cartname
checkoutname
ordername
init
teardown
stringifies
USD
runtime
wishlist
Googles
online
pluginpaths
CustomCart
LDAP
wildcard
wildcards
lastskuadded
wT
schemas
ModPerl
autoupdate
resultset
xxxx
xxxxxxxx
xxxxxxxxxxxx
WORKFLOW
preloading
refactor
IRC
MSSQL
Postgres
SQLite
dsns
username
orderid
PROPAGE
cenddate
ccm
ccname
ccstartdate
cctype
ccvn
ccy
ccn
pre
ccenddate
ccissuenumber
DateTime
escence
DBIC
forwards
UTF
CPANPLUS
Compat
resultsets
xml
YAML
m'kay
DBIx-Class-current
XPath
xpath
INI
