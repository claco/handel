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

    ## param 1 violations
    "Param 1 is not a HASH reference" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES",

    "Param 1 is not a HASH reference or Handel::Cart::Item" =>
        "Le param 1 n'est pas une référence d'cInformations PARASITES ou un Handel::Cart::Item",

    "Unknown restore mode" =>
        "Mode inconnu de restauration",

    "Currency code '[_1]' is invalid or malformed" =>
        "Le code '[_1]' de devise est inadmissible ou mal formé",

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
);

1;
__END__

=head1 NAME

Handel::L10N::fr - French Language Pack for Handel

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/