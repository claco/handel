use ExtUtils::MakeMaker;
use 5.006;
use strict;
use warnings FATAL => 'all';

eval 'use Apache::Test 1.16';
if (!$@) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));

    my @scripts = qw(t/TEST);

    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
};

WriteMakefile(
    NAME         => 'Handel',
    VERSION_FROM => 'lib/Handel.pm',
    AUTHOR       => 'Christopher H. Laco (cpan@chrislaco.com)',
    ABSTRACT     => 'Simple ecommerce framework with AxKit support',
    PREREQ_PM    => {
        'Class::DBI'       => '0.96',
        'DBI'              => '1.36',
        'Test::More'       => '0.48',
        'Error'            => '0.14',
        'Locale::Maketext' => '1.06'
    },
    (ExtUtils::MakeMaker->VERSION >= 6.11) ?
    (NO_META      => 1) : (),

    clean => { FILES => 't/cart*.db t/TEST t/logs t/htdocs/cart*.db' }
);
