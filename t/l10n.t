#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 11;
use utf8;

BEGIN {
    use_ok('Handel::L10N', 'translate');
    use_ok('Handel::Exception', ':try');

    #if ($] > 5.007) {
    #    require utf8;
    #    utf8->import;
    #};
};


## Check simple translation through Handel::L10N
{
    $Handel::L10N::handle = Handel::L10N->get_handle('en');
    is(translate('Language'), "English");

    $Handel::L10N::handle = Handel::L10N->get_handle('fr');
    is(translate('Language'), "Français");
};


## Test translation in exceptions
{
    $Handel::L10N::handle = Handel::L10N->get_handle('fr');

    ## check the stock exceptions
    try {
        throw Handel::Exception;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Une erreur non spécifiée s'est produite");
    };

    try {
        throw Handel::Exception::Constraint;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Le field(s) assuré a échoué des contraintes de base de données");
    };

    try {
        throw Handel::Exception::Argument;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "L'argument fourni est inadmissible ou du type inapproprié");
    };

    ## check translations when -details are included
    try {
        throw Handel::Exception(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Une erreur non spécifiée s'est produite: crap happens");
    };

    try {
        throw Handel::Exception::Constraint(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Le field(s) assuré a échoué des contraintes de base de données: crap happens");
    };

    try {
        throw Handel::Exception::Argument(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "L'argument fourni est inadmissible ou du type inapproprié: crap happens");
    };
};


## test translation within another module that uses the exceptions
{
    $Handel::L10N::handle = Handel::L10N->get_handle('fr');

    require Handel::Cart;

    try {
        my $cart = Handel::Cart->new(name => 'nothashref');
    } catch Handel::Exception with {
        my $E = shift;
        is ($E->text,
            "L'argument fourni est inadmissible ou du type inapproprié: Le param 1 n'est pas une référence d'cInformations PARASITES.");
    };
};
