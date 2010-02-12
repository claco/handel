## no critic
# $Id$
package Handel::L10N::de;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
};

%Lexicon = (
    Language => 'Deutsch',

    COMPAT_DEPRECATED =>
        'Handel::Compat ist missbilligt und wird künftig nicht mehr zur Verfügung stehen.',

    COMPCLASS_NOT_LOADED =>
        'Die Komponentenklasse [_1] [_2] konnte nicht geladen werden',

    PARAM1_NOT_HASHREF =>
        'Parameter 1 ist keine HASH-Referenz',

    PARAM1_NOT_HASHREF_CARTITEM =>
        'Parameter 1 ist weder eine HASH-Referenz noch ein Handel::Cart::Item-Objekt',

    PARAM1_NOT_HASHREF_CART =>
        'Parameter 1 ist weder eine HASH-Referenz noch ein Handel::Cart-Objekt',

    PARAM1_NOT_HASHREF_ORDER =>
        'Parameter 1 ist weder eine HASH-Referenz noch ein Handel::Order-Objekt',

    PARAM1_NOT_CHECKOUT_PHASE =>
        'Parameter 1 ist kein gültiger CHECKOUT_PHASE_*-Wert',

    PARAM1_NOT_CODEREF =>
        'Parameter 1 ist keine CODE-Referenz',

    PARAM1_NOT_CHECKOUT_MESSAGE =>
        'Parameter 1 ist weder ein Handel::Checkout::Message-Objekt noch eine Textnachricht',

    PARAM1_NOT_HASH_CARTITEM_ORDERITEM =>
        'Parameter 1 ist weder eine HASH-Referenz, noch ein Handel::Cart::Item- oder Handel::Order::Item-Objekt',

    PARAM1_NOT_ARRAYREF_STRING =>
        'Parameter 1 ist weder eine ARRAY-Referenz noch ein String',

    PARAM2_NOT_HASHREF =>
        'Parameter 2 ist keine HASH-Referenz',

    CARTPARAM_NOT_HASH_CART =>
        'Die Cart-Referenz ist weder eine HASH-Referenz noch ein Handel::Cart-Objekt',

    COLUMN_NOT_SPECIFIED =>
        'Es wurde keine Spalte festgelegt',

    COLUMN_NOT_FOUND =>
        'Die Spalte [_1] existiert nicht',

    COLUMN_VALUE_EXISTS =>
        'Der Wert [_1] existiert bereits',

    CONSTRAINT_NAME_NOT_SPECIFIED =>
        'Es wurde kein constraint-Name festgelegt',

    CONSTRAINT_NOT_SPECIFIED =>
        'Es wurde kein constraint festgelegt',

    UNKNOWN_RESTORE_MODE =>
        'Unbekannter restore-Modus',

    HANDLER_EXISTS_IN_PHASE =>
        'In der Phase ([_1]) gibt es bereits einen Handler für die Präferenz ([_2]) im Plugin ([_3])',

    CONSTANT_NAME_ALREADY_EXISTS =>
        'Es gibt bereits eine Konstante [_1] in Handel::Constants',

    CONSTANT_VALUE_ALREADY_EXISTS =>
        'Es gibt bereits einen konstanten Wert [_1]',

    CONSTANT_EXISTS_IN_CALLER =>
        'Es gibt bereits eine Konstante [_1] im caller [_2]',

    NO_ORDER_LOADED =>
        'Mit diesem checkout-Prozess ist keine Bestellung assoziiert',

    CART_NOT_FOUND =>
        'Zu diesem Suchkriterium wurde kein Einkaufswagen gefunden',

    ORDER_NOT_FOUND =>
        'Zu diesem Suchkriterium wurde keine Bestellung gefunden',

    ORDER_CREATE_FAILED_CART_EMPTY =>
        'Es konnte keine Bestellung angelegt werden weil der Einkaufswagen leer ist',

    ROLLBACK_FAILED =>
        'Die Transaktion wurde abgebrochen. Rollback fehlgeschlagen: [_1]',

    QUANTITY_GT_MAX =>
        'Die angeforderte Menge ([_1]) ist größer als die maximal erlaubte Menge ([_2])',

    CURRENCY_CODE_INVALID =>
        'Der Währungs-Code [_1] ist ungültig oder kaputt',

    UNHANDLED_EXCEPTION =>
        'Es ist ein unbekannter Fehler aufgetreten',

    CONSTRAINT_EXCEPTION =>
        'Die übergebenen Felder entsprachen nicht den Datenbank-constraints',

    ARGUMENT_EXCEPTION =>
        'Das übergebene Argument ist ungültig oder vom falschen Typ',

    XSP_TAG_EXCEPTION =>
        'Der tag ist nicht sichtbar oder es fehlen benötigte child-tags',

    ORDER_EXCEPTION =>
        'Während der Bereitstellung oder Überprüfung der Bestellung ist ein Fehler aufgetreten',

    CHECKOUT_EXCEPTION =>
        'Während des checkout-Prozesses ist ein Fehler aufgetreten',

    STORAGE_EXCEPTION =>
        'Beim Laden des storage ist ein Fehler aufgetreten',

    VALIDATION_EXCEPTION =>
        'Die Daten waren ungültig und konnten daher nicht geschrieben werden',

    VIRTUAL_METHOD =>
        'Die virtuelle Methode ist nicht implementiert',

    NO_STORAGE =>
        'Storage nicht übergeben',

    NO_RESULT_CLASS =>
        'Keine result-Klasse übergeben',

    NO_ITERATOR_DATA =>
        'Keine iterator-Daten übergeben',

    ITERATOR_DATA_NOT_ARRAYREF =>
        'Die iterator-Daten sind keine ARRAY-Referenz',

    ITERATOR_DATA_NOT_RESULTSET =>
        'Die iterator-Daten sind kein DBIx::Class::Resultset',

    ITERATOR_DATA_NOT_RESULTS_ITERATOR =>
        'Die iterator-Daten sind kein Iterator',

    NO_RESULT =>
        'Es existiert kein Ergebnis oder es wurde keines übergeben',

    NOT_CLASS_METHOD =>
        'Keine Klassenmethode',

    NOT_OBJECT_METHOD =>
        'Keine Objektmethode',

    FVS_REQUIRES_ARRAYREF =>
        'FormValidator::Simple benötigt ein Profil auf der Basis einer ARRAY-Referenz',

    DFV_REQUIRES_HASHREF =>
        'Data::FormValidator benötigt ein Profil auf der Basis einer HASH-Referenz',

    PLUGIN_HAS_NO_REGISTER =>
        'Versuch, ein Plugin zu registrieren, das kein register definiert hat',

    ADD_CONSTRAINT_EXISTING_SCHEMA =>
        'Zu einer existierenden schema-Instanz können keine constraints hinzugefügt werden',

    REMOVE_CONSTRAINT_EXISTING_SCHEMA =>
        'Von einer existierenden schema-Instanz können  eine constraints entfernt werden',

    SETUP_EXISTING_SCHEMA =>
        'Es wurde bereits eine schema-Instanz initialisiert',

    COMPDATA_EXISTING_SCHEMA =>
        'Konnte [_1] nicht einer existierenden schema-Instanz hinzufügen',

    ITEM_RELATIONSHIP_NOT_SPECIFIED =>
        'Keine item-Beziehung definiert',

    ITEM_STORAGE_NOT_DEFINED =>
        'Kein item-storage oder keine item-storage-Klasse definiert',

    SCHEMA_SOURCE_NOT_SPECIFIED =>
        'Keine schema_source spezifiziert',

    SCHEMA_CLASS_NOT_SPECIFIED =>
        'Keine schema_class spezifiziert',

    SCHEMA_SOURCE_NO_RELATIONSHIP =>
        'Die Quelle [_1] hat keine Beziehung namens [_2]',

    TAG_NOT_ALLOWED_IN_OTHERS =>
        'Tag [_1] ist innerhalb anderer Handel-tags ungültig',

    TAG_NOT_ALLOWED_HERE =>
        'Tag [_1] ist hier ungültig',

    TAG_NOT_ALLOWED_IN_TAG =>
        'Tag [_1] ist innerhalb von tag [_2] ungültig',

    NO_COLUMN_ACCESSORS =>
        'Storage hat keine Spalten-accessors zurückgegeben',
);

1;
__END__

=head1 NAME

Handel::L10N::de - Handel Language Pack: German (deutsch)

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

    Translation: Mirko Westermeier (mirko@westermeier.de)
