## no critic
# $Id$
package Handel::L10N::en_us;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
};

%Lexicon = (
    Language => 'English',

    COMPAT_DEPRECATED =>
        'Handel::Compat is deprecated and will go away in a future release.',

    COMPCLASS_NOT_LOADED =>
        'The component class [_1] [_2] could not be loaded',

    PARAM1_NOT_HASHREF =>
        'Param 1 is not a HASH reference',

    PARAM1_NOT_HASHREF_CARTITEM =>
        'Param 1 is not a HASH reference or Handel::Cart::Item',

    PARAM1_NOT_HASHREF_CART =>
        'Param 1 is not a HASH reference or Handel::Cart',

    PARAM1_NOT_HASHREF_ORDER =>
        'Param 1 is not a HASH reference or Handel::Order',

    PARAM1_NOT_CHECKOUT_PHASE =>
        'Param 1 is not a valid CHECKOUT_PHASE_* value',

    PARAM1_NOT_CODEREF =>
        'Param 1 is not a CODE reference',

    PARAM1_NOT_CHECKOUT_MESSAGE =>
        'Param 1 is not a Handel::Checkout::Message object or text message',

    PARAM1_NOT_HASH_CARTITEM_ORDERITEM =>
        'Param 1 is not a HASH reference, Handel::Cart::Item or Handel::Order::Item',

    PARAM1_NOT_ARRAYREF_STRING =>
        'Param 1 is not an ARRAY reference or string',

    PARAM2_NOT_HASHREF =>
        'Param 2 is not a HASH reference',

    CARTPARAM_NOT_HASH_CART =>
        'Cart reference is not a HASH reference or Handel::Cart',

    COLUMN_NOT_SPECIFIED =>
        'No column was specified',

    COLUMN_NOT_FOUND =>
        'Column [_1] does not exist',

    COLUMN_VALUE_EXISTS =>
        '[_1] value already exists',

    CONSTRAINT_NAME_NOT_SPECIFIED =>
        'No constraint name was specified',

    CONSTRAINT_NOT_SPECIFIED =>
        'No constraint was specified',

    UNKNOWN_RESTORE_MODE =>
        'Unknown restore mode',

    HANDLER_EXISTS_IN_PHASE =>
        'There is already a handler in phase ([_1]) for preference ([_2]) from the plugin ([_3])',

    CONSTANT_NAME_ALREADY_EXISTS =>
        'A constant named [_1] already exists in Handel::Constants',

    CONSTANT_VALUE_ALREADY_EXISTS =>
        'A phase constant value of [_1] already exists',

    CONSTANT_EXISTS_IN_CALLER =>
        'A constant named [_1] already exists in caller [_2]',

    NO_ORDER_LOADED =>
        'No order is assocated with this checkout process',

    CART_NOT_FOUND =>
        'Could not find a cart matching the supplied search criteria',

    ORDER_NOT_FOUND =>
        'Could not find an order matching the supplied search criteria',

    ORDER_CREATE_FAILED_CART_EMPTY =>
        'Could not create a new order because the supplied cart is empty',

    ROLLBACK_FAILED =>
        'Transaction aborted. Rollback failed: [_1]',

    QUANTITY_GT_MAX =>
        'The quantity requested ([_1]) is greater than the maximum quantity allowed ([_2])',

    CURRENCY_CODE_INVALID =>
        'Currency code [_1] is invalid or malformed',

    UNHANDLED_EXCEPTION =>
        'An unspecified error has occurred',

    CONSTRAINT_EXCEPTION =>
        'The supplied field(s) failed database constraints',

    ARGUMENT_EXCEPTION =>
        'The argument supplied is invalid or of the wrong type',

    XSP_TAG_EXCEPTION =>
        'The tag is out of scope or missing required child tags',

    ORDER_EXCEPTION =>
        'An error occurred while while creating or validating the current order',

    CHECKOUT_EXCEPTION =>
        'An error occurred during the checkout process',

    STORAGE_EXCEPTION =>
        'An error occurred while loading storage',

    VALIDATION_EXCEPTION =>
        'The data could not be written because it failed validation',

    VIRTUAL_METHOD =>
        'Virtual method not implemented',

    NO_STORAGE =>
        'Storage not supplied',

    NO_RESULT_CLASS =>
        'Result class not supplied',

    NO_ITERATOR_DATA =>
        'Iterator data not supplied',

    ITERATOR_DATA_NOT_ARRAYREF =>
        'Iterator data is not an ARRAY reference',

    ITERATOR_DATA_NOT_RESULTSET =>
        'Iterator data is not a DBIx::Class::Resultset',

    ITERATOR_DATA_NOT_RESULTS_ITERATOR =>
        'Iterator data is not an iterator',

    NO_RESULT =>
        'No result exists or result not supplied',

    NOT_CLASS_METHOD =>
        'Not a class method',

    NOT_OBJECT_METHOD =>
        'Not an object method',

    FVS_REQUIRES_ARRAYREF =>
        'FormValidator::Simple requires an ARRAYREF based profile',

    DFV_REQUIRES_HASHREF =>
        'Data::FormValidator requires an HASHREF based profile',

    PLUGIN_HAS_NO_REGISTER =>
        'Attempt to register plugin that hasn\'t defined register',

    ADD_CONSTRAINT_EXISTING_SCHEMA =>
        'Can not add constraints to an existing schema instance',

    REMOVE_CONSTRAINT_EXISTING_SCHEMA =>
        'Can not remove constraints to an existing schema instance',

    SETUP_EXISTING_SCHEMA =>
        'A schema instance has already been initialized',

    COMPDATA_EXISTING_SCHEMA =>
        'Can not assign [_1] to an existing schema instance',

    ITEM_RELATIONSHIP_NOT_SPECIFIED =>
        'No item relationship defined',

    ITEM_STORAGE_NOT_DEFINED =>
        'No item storage or item storage class defined',

    SCHEMA_SOURCE_NOT_SPECIFIED =>
        'No schema_source is specified',

    SCHEMA_CLASS_NOT_SPECIFIED =>
        'No schema_class is specified',

    SCHEMA_SOURCE_NO_RELATIONSHIP =>
        'The source [_1] has no relationship named [_2]',

    TAG_NOT_ALLOWED_IN_OTHERS =>
        'Tag [_1] not valid inside of other Handel tags',

    TAG_NOT_ALLOWED_HERE =>
        'Tag [_1] not valid here',

    TAG_NOT_ALLOWED_IN_TAG =>
        'Tag [_1] not valid inside of tag [_2]',

    NO_COLUMN_ACCESSORS =>
        'Storage did not return any column accessors',
);

1;
__END__

=head1 NAME

Handel::L10N::en_us - Handel Language Pack: US English

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
