use ExtUtils::MakeMaker;
use 5.6.1;

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
        'Locale::Maketext' => undef
    },
    NO_META      => 1,
    clean => { FILES => 't/cart*.db' }
);
