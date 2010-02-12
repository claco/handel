#!perl -w
use strict;
use warnings;
use utf8;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 12;

    use_ok('Handel::L10N', 'translate');
    use_ok('Handel::Exception', ':try');
};


## Check simple translation through Handel::L10N
{
    local %ENV = ();
    local $ENV{'LANGUAGE'} = 'en';
    is(translate('Language'), "English", 'got English');

    local $ENV{'LANGUAGE'} = 'fr';
    is(translate('Language'), "Français", 'got French');

    local $ENV{'LANGUAGE'} = 'de';
    is(translate('Language'), "Deutsch", 'got German');
};


## Test translation in exceptions
{
    local %ENV = ();
    local $ENV{'LANGUAGE'} = 'fr';

    ## check the stock exceptions
    try {
        throw Handel::Exception;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Une erreur non spécifiée s'est produite", 'got french exception');
    };

    try {
        throw Handel::Exception::Constraint;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            'Le champ recu ne respecte pas les contraintes de la base de données', 'got french exception');
    };

    try {
        throw Handel::Exception::Argument;
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            'L\'argument fourni est invalide ou d\'un mauvais type', 'got french exception');
    };

    ## check translations when -details are included
    try {
        throw Handel::Exception(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            "Une erreur non spécifiée s'est produite: crap happens", 'got french exception');
    };

    try {
        throw Handel::Exception::Constraint(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            'Le champ recu ne respecte pas les contraintes de la base de données: crap happens', 'got french exception');
    };

    try {
        throw Handel::Exception::Argument(-details => 'crap happens');
    } catch Handel::Exception with {
        my $E = shift;
        is($E->text,
            'L\'argument fourni est invalide ou d\'un mauvais type: crap happens', 'got french exception');
    };
};


## test translation within another module that uses the exceptions
{
    local %ENV = (Path => '');
    local $ENV{'LANGUAGE'} = 'fr';

    require Handel::Cart;

    try {
        my $cart = Handel::Cart->create(name => 'nothashref');

        fail('no exception thrown');
    } catch Handel::Exception with {
        my $E = shift;
        is ($E->text,
            'L\'argument fourni est invalide ou d\'un mauvais type: Le paramètre 1 n\'est pas une référence à un tableau associatif (HASH)', 'got french exception');
    } otherwise {
        fail('caught other exception');
    };
};
