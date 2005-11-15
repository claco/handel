#!perl -w
# $Id$
use strict;
use warnings;
use Test::More;

eval 'use Test::Spelling';
plan skip_all => 'Test::Spelling not installed' if $@;
plan skip_all => 'set TEST_SPELLING to enable this test' unless $ENV{TEST_SPELLING};

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
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
