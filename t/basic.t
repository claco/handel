#!perl -wT
# $Id: basic.t 4 2004-12-28 03:01:15Z claco $
use Test::More tests => 12;

BEGIN {
    use_ok('Handel');
    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constants');
    use_ok('Handel::Constraints');
    use_ok('Handel::DBI');
    use_ok('Handel::Exception');
    use_ok('Handel::Iterator');
    use_ok('Handel::L10N');
    use_ok('Handel::L10N::en_us');
    use_ok('Handel::L10N::fr');

    SKIP: {
        skip 'AxKit not installed', 1 unless eval 'use AxKit';

        use_ok('AxKit::XSP::Handle::Cart');
    };
};
