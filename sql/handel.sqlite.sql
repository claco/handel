-- $Id$
CREATE TABLE cart (
	id varchar(36) NOT NULL default '',
	shopper varchar(36) NOT NULL default '',
	type tinyint(3) NOT NULL default '0',
	name varchar(50) default NULL,
	description varchar(255) default NULL,
	PRIMARY KEY (id)
);

CREATE TABLE cart_items (
	id varchar(36) NOT NULL default '',
	cart varchar(36) NOT NULL default '',
	sku varchar(25) NOT NULL default '',
	quantity tinyint(3) NOT NULL default '1',
	price decimal(9,2) NOT NULL default '0.00',
	description varchar(255) default NULL,
	PRIMARY KEY (id)
);

CREATE TABLE orders (
	id varchar(36) NOT NULL default '',
	shopper varchar(36) NOT NULL default '',
	type tinyint(3) NOT NULL default '0',
	number varchar(20) NULL,
	created datetime(19) NULL,
	updated datetime(19) NULL,
	comments varchar(100) NULL,
	shipmethod varchar(10) NULL,
	shipping decimal(9,2) NOT NULL default '0.00',
	handling decimal(9,2) NOT NULL default '0.00',
	tax decimal(9,2) NOT NULL default '0.00',
	subtotal decimal(9,2) NOT NULL default '0.00',
	total decimal(9,2) NOT NULL default '0.00',
	billtofirstname varchar(25) NULL,
	billtolastname varchar(25) NULL,
	billtoaddress1 varchar(50) NULL,
	billtoaddress2 varchar(50) NULL,
	billtoaddress3 varchar(50) NULL,
	billtocity varchar(50) NULL,
	billtostate varchar(50) NULL,
	billtozip varchar(10) NULL,
	billtocountry varchar(25) NULL,
	billtodayphone varchar(25) NULL,
	billtonightphone varchar(25) NULL,
	billtofax varchar(25) NULL,
	billtoemail varchar(50) NULL,
	shiptosameasbillto tinyint(3) NOT NULL  default '0',
	shiptofirstname varchar(25) NULL,
	shiptolastname varchar(25) NULL,
	shiptoaddress1 varchar(50) NULL,
	shiptoaddress2 varchar(50) NULL,
	shiptoaddress3 varchar(50) NULL,
	shiptocity varchar(50) NULL,
	shiptostate varchar(50) NULL,
	shiptozip varchar(10) NULL,
	shiptocountry varchar(25) NULL,
	shiptodayphone varchar(25) NULL,
	shiptonightphone varchar(25) NULL,
	shiptofax varchar(25) NULL,
	shiptoemail varchar(50) NULL,
	PRIMARY KEY (id)
);

CREATE TABLE order_items (
	id varchar(36) NOT NULL default '',
	orderid varchar(36) NOT NULL default '',
	sku varchar(25) NOT NULL default '',
	quantity tinyint(3) NOT NULL default '1',
	price decimal(9,2) NOT NULL default '0.00',
	description varchar(255) default NULL,
	total decimal(9,2) NOT NULL default '0.00',
	PRIMARY KEY (id)
);
