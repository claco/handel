## no critic
# $Id$
package Handel::L10N::fr;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
};

%Lexicon = (
    Language => 'Français',

    COMPAT_DEPRECATED =>
        'Handel::Compat est obsolète et sera retiré dans la prochaine version.',

    COMPCLASS_NOT_LOADED =>
        'The component class [_1] [_2] could not be loaded',

    PARAM1_NOT_HASHREF =>
        'Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH)',

    PARAM1_NOT_HASHREF_CARTITEM =>
        'Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH) ou un Handel::Cart::Item',

    PARAM1_NOT_HASHREF_CART =>
        'Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH) ou un Handel::Cart',

    PARAM1_NOT_HASHREF_ORDER =>
        'Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH) ou un Handel::Order',

    PARAM1_NOT_CHECKOUT_PHASE =>
        'Le paramètre 1 n\'est pas une valeur CHECKOUT_PHASE_*',

    PARAM1_NOT_CODEREF =>
        'Le paramètre 1 n\'est pas une référence CODE',

    PARAM1_NOT_CHECKOUT_MESSAGE =>
        'Le paramètre 1 n\'est pas un objet Handel::Checkout::Message ou un message texte',

    PARAM1_NOT_HASH_CARTITEM_ORDERITEM =>
        'Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH) ou un Handel::Cart::Item ou un Handel::Order::Item',

    PARAM1_NOT_ARRAYREF_STRING =>
        'Le paramètre 1 n\'est pas une référence à un tableau ou une chaine de caractères',

    PARAM2_NOT_HASHREF =>
        'Le paramètre 2 n\'est pas une référence à un tableau associatif (HASH)',

    CARTPARAM_NOT_HASH_CART =>
        'La référence Panier n\'est pas une référence à un tableau associatif (HASH) ou un Handel::Cart',

    COLUMN_NOT_SPECIFIED =>
        'Aucune colonne spécifiée',

    COLUMN_NOT_FOUND =>
        'La colonne [_1] n\'a pas été trouvée',

    COLUMN_VALUE_EXISTS =>
        'La valeur [_1] existe déjà',

    CONSTRAINT_NAME_NOT_SPECIFIED =>
        'Aucun nom de contrainte spécifié',

    CONSTRAINT_NOT_SPECIFIED =>
        'Aucune contrainte spécifiée',

    UNKNOWN_RESTORE_MODE =>
        'Mode de restauration inconnu',

    HANDLER_EXISTS_IN_PHASE =>
        'Il y a déjà un handler en phase ([_1]) pour la préférence ([_2]) depuis le plugin ([_3])',

    CONSTANT_NAME_ALREADY_EXISTS =>
        'Une constante appelée [_1] existe déjà dans Handel::Constants',

    CONSTANT_VALUE_ALREADY_EXISTS =>
        'Une valeur constante de phase de [_1] existe déjà',

    CONSTANT_EXISTS_IN_CALLER =>
        'Une constante appelée [_1] existe déjà dans l\'appel [_2]',

    NO_ORDER_LOADED =>
        'Aucune commande n\'est associée a ce processus de paiement',

    CART_NOT_FOUND =>
        'Aucun panier ne correspondant aux critères de recherche fournis',

    ORDER_NOT_FOUND =>
        'Aucune commande ne correspondant aux critères de recherche fournis',

    ORDER_CREATE_FAILED_CART_EMPTY =>
        'Impossible de créer une nouvelle commande, le panier fourni est vide',

    ROLLBACK_FAILED =>
        'Transaction abandonnée. Echec de Rollback [_1]',

    QUANTITY_GT_MAX =>
        'La quantité demandé ([_1]) est plus grande que la quantité maximale permise ([_2])',

    CURRENCY_CODE_INVALID =>
        'Le code devise [_1] est invalide ou malformé',

    UNHANDLED_EXCEPTION =>
        'Une erreur non spécifiée s\'est produite',

    CONSTRAINT_EXCEPTION =>
        'Le champ recu ne respecte pas les contraintes de la base de données',

    ARGUMENT_EXCEPTION =>
        'L\'argument fourni est invalide ou d\'un mauvais type',

    XSP_TAG_EXCEPTION =>
        'L\'étiquette est hors de portée ou il manque les étiquettes filles réquises',

    ORDER_EXCEPTION =>
        'Une erreur s\'est produite lors de la validation ou de la création de la commande en cours',

    CHECKOUT_EXCEPTION =>
        'Une erreur s\'est produite pendant le processus de paiement',

    STORAGE_EXCEPTION =>
        'Une erreur s\'est produite pendant le chargement du stockage',

    VALIDATION_EXCEPTION =>
        'Echec de la validation, les données ne peuvent pas être enregistré',

    VIRTUAL_METHOD =>
        'Les méthodes virtuels ne sont pas implémentés',

    NO_STORAGE =>
        'Le stockage n\'est pas fourni',

    NO_RESULT_CLASS =>
        'Le résultat de la classe n\'est pas fourni',

    NO_ITERATOR_DATA =>
        'Les données d\'itération ne sont pas fournies',

    ITERATOR_DATA_NOT_ARRAYREF =>
        'Les données d\'itération ne sont pas une référence à un tableau',

    ITERATOR_DATA_NOT_RESULTSET =>
        'Les données d\'itération ne sont pas un DBIx::Class::Resultset',

    ITERATOR_DATA_NOT_RESULTS_ITERATOR =>
        'Les données d\'itération ne sont pas une itération',

    NO_RESULT =>
        'Aucun résultat ou résultat non fourni',

    NOT_CLASS_METHOD =>
        'N\'est pas une méthode de la classe',

    NOT_OBJECT_METHOD =>
        'N\'est pas une méthode de l\'objet',

    FVS_REQUIRES_ARRAYREF =>
        'FormValidator::Simple a besoin d\'un profil sous forme de référence à un tableau',

    DFV_REQUIRES_HASHREF =>
        'Data::FormValidator a besoin d\'un profil sous forme de référence à un tableau associatif (HASH)',

    PLUGIN_HAS_NO_REGISTER =>
        'Tentative d\'enregistrement d\'un plugin sans définition d\'enregistrement',

    ADD_CONSTRAINT_EXISTING_SCHEMA =>
        'Ne peut pas ajouter des contraintes à une instance de schéma existante',

    REMOVE_CONSTRAINT_EXISTING_SCHEMA =>
        'Ne peut pas enlever des contraintes à une instance de schéma existante',

    SETUP_EXISTING_SCHEMA =>
        'Une instance de schéma a déjà été initialisé',

    COMPDATA_EXISTING_SCHEMA =>
        'Ne peut pas assigner [_1] à une instance d\'un schéma existant',

    ITEM_RELATIONSHIP_NOT_SPECIFIED =>
        'Aucun élément de relation défini',

    ITEM_STORAGE_NOT_DEFINED =>
        'Aucun élément de stockage ou d\'élément classe de stockage défini ',

    SCHEMA_SOURCE_NOT_SPECIFIED =>
        'Aucun schema_source spécifié',

    SCHEMA_CLASS_NOT_SPECIFIED =>
        'Aucun schema_class spécifié',

    SCHEMA_SOURCE_NO_RELATIONSHIP =>
        'La source [_1] n\'a pas de relation appelée [_2]',

    TAG_NOT_ALLOWED_IN_OTHERS =>
        'Étiquette [_1] invalide à l\'intérieur d\'autres étiquettes Handel',

    TAG_NOT_ALLOWED_HERE =>
        'Étiquette [_1] invalide ici',

    TAG_NOT_ALLOWED_IN_TAG =>
        'Étiquette [_1] invalide à l\'intérieur de l\'étiquettes [_2]',

    NO_COLUMN_ACCESSORS =>
        'Le stockage ne retourne pas d\'accès aux colonnes',
);

1;
__END__

=head1 NAME

Handel::L10N::fr - Handel Language Pack: French

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

    Translation : Pierrick DINTRAT
