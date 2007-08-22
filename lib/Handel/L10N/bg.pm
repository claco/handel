## no critic
# $Id$
package Handel::L10N::bg;
use strict;
use warnings;
use utf8;
use vars qw/%Lexicon/;

BEGIN {
    use base qw/Handel::L10N/;
};

%Lexicon = (
    Language => 'Български',

    COMPAT_DEPRECATED =>
        'Handel::Compat е остарял и ще бъде премахнат в бъдещите издания.',

    COMPCLASS_NOT_LOADED =>
        'Компонентния клас [_1] [_2] не може да бъде зареден',

    PARAM1_NOT_HASHREF =>
        'Параметър 1 не е хеш-указател',

    PARAM1_NOT_HASHREF_CARTITEM =>
        'Параметър 1 не е хеш-указател или тип Handel::Cart::Item',

    PARAM1_NOT_HASHREF_CART =>
        'Параметър 1 не е хеш-указател тип Handel::Cart',

    PARAM1_NOT_HASHREF_ORDER =>
        'Параметър 1 не е хеш-указател или тип Handel::Order',

    PARAM1_NOT_CHECKOUT_PHASE =>
        'Параметър 1 не е валидна CHECKOUT_PHASE_* стойност',

    PARAM1_NOT_CODEREF =>
        'Параметър 1 не е код-указател',

    PARAM1_NOT_CHECKOUT_MESSAGE =>
        'Параметър 1 не е Handel::Checkout::Message обект или текстово съобщения',

    PARAM1_NOT_HASH_CARTITEM_ORDERITEM =>
        'Параметър 1 не е хеш-указател, от тип Handel::Cart::Item или тип Handel::Order::Item',

    PARAM1_NOT_ARRAYREF_STRING =>
        'Параметър 1 не е указател към масив или низ',

    PARAM2_NOT_HASHREF =>
        'Параметър 1 не е хеш-указател',

    CARTPARAM_NOT_HASH_CART =>
        'Cart-указателя не е хеш-указател или от тип Handel::Cart',

    COLUMN_NOT_SPECIFIED =>
        'Не е упомената колона',

    COLUMN_NOT_FOUND =>
        'Колоната [_1] не съществува',

    COLUMN_VALUE_EXISTS =>
        '[_1] вече съществува',

    CONSTRAINT_NAME_NOT_SPECIFIED =>
        'Не е указано име за ограничението',

    CONSTRAINT_NOT_SPECIFIED =>
        'Не е упоменато ограничение',

    UNKNOWN_RESTORE_MODE =>
        'Неизвестен режим на възстановяване',

    HANDLER_EXISTS_IN_PHASE =>
        'Вече има хендлър във фаза ([_1]) за опцията ([_2]) от плъгин ([_3])',

    CONSTANT_NAME_ALREADY_EXISTS =>
        'Константата [_1] вече съществува в Handel::Constants',

    CONSTANT_VALUE_ALREADY_EXISTS =>
        'Стойността на константата [_1] вече съшествува',

    CONSTANT_EXISTS_IN_CALLER =>
        'Константата [_1] вече съществува за caller [_2]',

    NO_ORDER_LOADED =>
        'Не съществува поръчка, която да е свързана с потвърждаването на поръчката',

    CART_NOT_FOUND =>
        'Не може да бъде намерена количка за пазаруване, отговаряща на зададените критерии',

    ORDER_NOT_FOUND =>
        'Не може да бъде намерена поръчка, отговаряща на зададените критерии',

    ORDER_CREATE_FAILED_CART_EMPTY =>
        'Не може да бъде създадена нова поръчка, защото количката за пазаруване е празна',

    ROLLBACK_FAILED =>
        'Транзакцията прекъсна. Възстановяването се провали: [_1]',

    QUANTITY_GT_MAX =>
        'Заявеното количество ([_1]) е повече от максимално позволеното ([_2])',

    CURRENCY_CODE_INVALID =>
        'Валутната абревиатура [_1] е невалидна или непълна',

    UNHANDLED_EXCEPTION =>
        'Възникна неопределена грешка',

    CONSTRAINT_EXCEPTION =>
        'Предоставеното(ите) поле(та) нарушават ограниченията на базата-данни',

    ARGUMENT_EXCEPTION =>
        'Указаният аргумент е невалиден или от грешен тип',

    XSP_TAG_EXCEPTION =>
        'Етикетът не е отчетен или му липсват задължителните под-етикети',

    ORDER_EXCEPTION =>
        'Възникна грешка докато се създаваше или валидираше текущата поръчка',

    CHECKOUT_EXCEPTION =>
        'Възникна грешка по време на потвърждаването на поръчката',

    STORAGE_EXCEPTION =>
        'Възникна грешка по време на зареждане на хранилището',

    VALIDATION_EXCEPTION =>
        'Данните са невалидни и не могат да бъдат записани',

    VIRTUAL_METHOD =>
        'Неимплементиран виртуален метод',

    NO_STORAGE =>
        'Не е упомента контейнер',

    NO_RESULT_CLASS =>
        'Не е упоменат клас за резултати',

    NO_ITERATOR_DATA =>
        'Не е упоменат итератор',

    ITERATOR_DATA_NOT_ARRAYREF =>
        'Данните от итератора не са указател към масив',

    ITERATOR_DATA_NOT_RESULTSET =>
        'Данните от итератора не са DBIx::Class::Resultset',

    ITERATOR_DATA_NOT_RESULTS_ITERATOR =>
        'Данните от итератора не са итератор',

    NO_RESULT =>
        'Няма резултат или такъв не е предоставен',

    NOT_CLASS_METHOD =>
        'Не е метод на клас',

    NOT_OBJECT_METHOD =>
        'Не е метод на обект',

    FVS_REQUIRES_ARRAYREF =>
        'FormValidator::Simple изисква ARRAYREF профил',

    DFV_REQUIRES_HASHREF =>
        'Data::FormValidator изисква HASHREF профил',

    PLUGIN_HAS_NO_REGISTER =>
        'Опит за регистриране на плъгин, който не дефинира метод register',

    ADD_CONSTRAINT_EXISTING_SCHEMA =>
        'Към текущата схема не могат да се добавят ограничения',

    REMOVE_CONSTRAINT_EXISTING_SCHEMA =>
        'От текущата схема не могат да се премахват ограничения',

    SETUP_EXISTING_SCHEMA =>
        'Текущата схема вече е инициализирана',

    COMPDATA_EXISTING_SCHEMA =>
        '[_1] не може да бъде присвоена към текущата схема',

    ITEM_RELATIONSHIP_NOT_SPECIFIED =>
        'Не са дефинирани релации между единиците',

    ITEM_STORAGE_NOT_DEFINED =>
        'Няма място или дефиниран клас за съхранение на отделните единици',

    SCHEMA_SOURCE_NOT_SPECIFIED =>
        'Не е упоменат schema_source',

    SCHEMA_CLASS_NOT_SPECIFIED =>
        'Не е упоменат schema_class',

    SCHEMA_SOURCE_NO_RELATIONSHIP =>
        'Източникът [_1] няма релация с име [_2]',

    TAG_NOT_ALLOWED_IN_OTHERS =>
        'Етикетът [_1] не е валиден в други Handel етикети',

    TAG_NOT_ALLOWED_HERE =>
        'Етикетът [_1] не е валиден тук',

    TAG_NOT_ALLOWED_IN_TAG =>
        'Етикетът [_1] не е валиден в етикета [_2]',

    NO_COLUMN_ACCESSORS =>
        'Хранилището не върна никакви манипулатори на колони',
);

1;
__END__

=head1 NAME

Handel::L10N::bg - Handel Language Pack: Bulgarian

=head1 AUTHOR

    Kliment A. Ognianov
    CPAN ID: <NONE>
    kleo@pro-nova.org
    http://www.pro-nova.net/
