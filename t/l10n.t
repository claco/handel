#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 11;
use utf8;

BEGIN {
    use_ok('Handel::L10N', 'translate');
    use_ok('Handel::Exception', ':try');
};


## Check simple translation through Handel::L10N
{
    local %ENV = ();
    local $ENV{'LANG'} = 'en';
    is(translate('Language'), "English");

    local $ENV{'LANG'} = 'fr';
    is(translate('Language'), "Français");
};


## Test translation in exceptions
{
    local %ENV = ();
    local $ENV{'LANG'} = 'fr';

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
            "Le champ recu n'a pas satisfait aux contraintes de base de données");
    };

    try {
        throw Handel::Exception::Argument;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "L'argument fourni est invalide ou du type inapproprié");
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
            "Le champ recu n'a pas satisfait aux contraintes de base de données: crap happens");
    };

    try {
        throw Handel::Exception::Argument(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "L'argument fourni est invalide ou du type inapproprié: crap happens");
    };
};


## test translation within another module that uses the exceptions
{
    local %ENV = ();
    local $ENV{'LANG'} = 'fr';

    require Handel::Cart;

    try {
        my $cart = Handel::Cart->new(name => 'nothashref');

        fail;
    } catch Handel::Exception with {
        my $E = shift;
        is ($E->text,
            "L'argument fourni est invalide ou du type inapproprié: Le parametre 1 n'est pas une reference a un tableau associatif (HASH).");
    } otherwise {
        fail;
    };
};
