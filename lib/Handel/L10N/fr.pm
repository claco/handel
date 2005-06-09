# $Id$
package Handel::L10N::fr;
use strict;
use warnings;
use utf8;
use vars qw(%Lexicon);

BEGIN {
    use base 'Handel::L10N';
};

%Lexicon = (
    "Language" =>
        "Français",

    ## Base exceptions
    "An unspecified error has occurred" =>
        "Une erreur non spécifiée s'est produite",

    "The supplied field(s) failed database constraints" =>
        "Le field(s) assuré a échoué des contraintes de base de données",

    "The argument supplied is invalid or of the wrong type" =>
        "L'argument fourni est inadmissible ou du type inapproprié",

    "Required modules not found" =>
        "Modules requis non trouvés",

    "The quantity requested ([_1]) is greater than the maximum quantity allowed ([_2])" =>
        "La quantité a demandé ([_1]) est plus grande que la quantité maximum a permis ([_2])",

    "An error occurred while while creating or validating the current order" =>
        "Une erreur s'est produite tandis que tout en créant ou validant l'ordre courant",

    "An error occurred during the checkout process" =>
        "Une erreur s'est produite pendant le procédé de contrôle",

    ## param 1 violations
    "Param 1 is not a HASH reference" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES",

    "Cart reference is not a HASH reference or Handel::Cart" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES ou un Handel::Cart",

    "Param 1 is not a HASH reference or Handel::Cart::Item" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES ou un Handel::Cart::Item",

    "Unknown restore mode" =>
        "Mode inconnu de restauration",

    "Currency code '[_1]' is invalid or malformed" =>
        "Le code '[_1]' de devise est inadmissible ou mal formé",

    "Param 1 is not a a valid CHECKOUT_PHASE_* value" =>
        "Le param 1 n'est pas une valeur valide de CHECKOUT_PHASE_*",

    "Param 1 is not a CODE reference" =>
        "Le param 1 n'est pas une référence de CODE",

    "Param 1 is not an ARRAY reference" =>
        "Le param 1 n'est pas une référence de RANGÉE",

    "Param 1 is not a HASH reference, Handel::Order object, or order id" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES, objet de Handel::Order, ou identification d'ordre",

    "Param 1 is not a HASH reference, Handel::Order object, or order id" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES, objet de Handel::Cart, ou identification de chariot",

    ## Taglib exceptions
    "Tag '[_1]' not valid inside of other Handel tags" =>
        "L'étiquette '[_1] 'peut intérieur inadmissible d'autres étiquettes de Handel",

    "Tag '[_1]' not valid here" =>
        "Étiquette '[_1]' inadmissible ici",

    ## naughty bits
    "has invalid value" =>
        "a la valeur inadmissible",

    "[_1] value already exists" =>
        "[_1] la valeur existe déjà",

    ## Order exceptions
    "Could not find a cart matching the supplid search criteria" =>
        "N'a pas pu trouver un chariot assortir les critères de recherche de supplid",

    "Could not create a new order because the supplied cart is empty" =>
        "Ne pourrait pas créer un nouvel ordre parce que le chariot fourni est vide",
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