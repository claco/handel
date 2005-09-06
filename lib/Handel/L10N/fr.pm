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
        "Le champ recu n'a pas satisfait aux contraintes de base de données",

    "The argument supplied is invalid or of the wrong type" =>
        "L'argument fourni est invalide ou du type inapproprié",

    "Required modules not found" =>
        "Modules requis non trouvés",

    "The quantity requested ([_1]) is greater than the maximum quantity allowed ([_2])" =>
        "La quantité demandé ([_1]) est plus grande que la quantité maximale permise ([_2])",

    "An error occurred while while creating or validating the current order" =>
        "Une erreur s'est produite lors de la validation ou de la creation de la commande en cours",

    "An error occurred during the checkout process" =>
        "Une erreur s'est produite pendant le processus de paiement",

    ## param 1 violations
    "Param 1 is not a HASH reference" =>
        "Le parametre 1 n'est pas une reference a un tableau associatif (HASH)",

    "Cart reference is not a HASH reference or Handel::Cart" =>
        "La reference au panier (Cart) n'est pas une reference a un tableau associatif (HASH) ou un Handel::Cart",

    "Param 1 is not a HASH reference or Handel::Cart::Item" =>
        "Le parametre 1 n'est pas une reference a un tableau associatif (HASH) ou a un Handel::Cart::Item",

    "Param 1 is not a HASH reference, Handel::Order::Item or Handel::Cart::Item" =>
        "Le parametre 1 n'est pas une reference a un tableau associatif (HASH) ou a un Handel::Order::Item ou un Handel::Cart::Item",

    "Unknown restore mode" =>
        "Mode inconnu de restauration",

    "Currency code '[_1]' is invalid or malformed" =>
        "Le code de devise '[_1]' est invalide ou mal formé",

    "Param 1 is not a a valid CHECKOUT_PHASE_* value" =>
        "Le parametre 1 n'est pas une valeur valide de CHECKOUT_PHASE_*",

    "Param 1 is not a CODE reference" =>
        "Le parametre 1 n'est pas une référence de CODE",

    "Param 1 is not an ARRAY reference" =>
        "Le parametre 1 n'est pas une référence de TABLEAU",

    "Param 1 is not an ARRAY reference or string" =>
        "Le parametre 1 n'est pas une référence de TABLEAU ou de chaine de caracteresE",

    "Param 1 is not a HASH reference, Handel::Order object, or order id" =>
        "Le parametre 1 n'est pas une référence a un tableau associatif (HASH), un objet de Handel::Cart, ou un identifiant de commande",

    "Param 1 is not a Handel::Checkout::Message object or text message" =>
        "Le parametre 1 n'est pas un message de texte ni un objet de Handel::Checkout::Message",

    ## Taglib exceptions
    "Tag '[_1]' not valid inside of other Handel tags" =>
        "L'étiquette '[_1] 'ne peut resider a l'interieur d'autres étiquettes de Handel",

    "Tag '[_1]' not valid here" =>
        "Étiquette '[_1]' nvalide ici",

    ## naughty bits
    "has invalid value" =>
        "a une valeur invalide",

    "[_1] value already exists" =>
        "la valeur [_1] existe déjà",

    ## Order exceptions
    "Could not find a cart matching the supplid search criteria" =>
        "N'a pas pu trouver un panier correspondant aux critères de recherche fournis",

    "Could not create a new order because the supplied cart is empty" =>
        "Impossible de créer une nouvelle commande parce que le panier fourni est vide",

    ## Checkout exception
    "No order is assocated with this checkout process" =>
        "Aucune commande n'est associee a ce processus de paiement",
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