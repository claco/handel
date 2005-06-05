#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More tests => 19;

BEGIN {
    use_ok('Handel');
    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Checkout');
    use_ok('Handel::Checkout::Plugin');
    use_ok('Handel::Constants');
    use_ok('Handel::Constraints');
    use_ok('Handel::Currency');
    use_ok('Handel::DBI');
    use_ok('Handel::Exception');
    use_ok('Handel::Iterator');
    use_ok('Handel::L10N');
    use_ok('Handel::L10N::en_us');
    use_ok('Handel::L10N::fr');
    use_ok('Handel::Order');
    use_ok('Handel::Order::Item');

    SKIP: {
        eval 'use Apache::AxKit::Language::XSP';
        skip 'AxKit not installed', 1 if $@;

        {
            ## squelch AxKit strict/warnings
            no strict;
            no warnings;
            use_ok('AxKit::XSP::Handel::Cart');
        };
    };

    SKIP: {
        eval 'use Template 2.07';
        skip 'Template Toolkit 2.07 not installed', 2 if $@;

        use_ok('Template::Plugin::Handel::Cart');
        use_ok('Template::Plugin::Handel::Constants');
    };
};
