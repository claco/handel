# $Id$
use ExtUtils::MakeMaker;
use 5.006;
use strict;
use warnings FATAL => 'all';

require Test::More;
if (Test::More->VERSION < 0.48) {
    print "\a\a\a\a\a";
    print "----------------------------------------------------------\n";
    print "Test::More < 0.48 sometimes causes test failures with\n";
    print "Class::DBI/IMA::DBI. Please consider updating Test::More\n";
    print "to version 0.48 or greater if you experience test failures\n";
    print "with 'attemt to free unreferenced scalar' errors.\n";
    print "----------------------------------------------------------\n";
    sleep 5;
};

eval 'use Apache::Test 1.16';
if (!$@) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));

    my @defines;

    eval 'use Apache::Template';
    if (!$@) {
        push @defines, 'TT2';
    };

    ## for whatever reason, use AxKit causes issues
    ## use-ing A::A::Exception doesn't
    eval 'use Apache::AxKit::Exception';
    if (!$@) {
        push @defines, 'AXKIT';
    };

    push(@ARGV, '-defines', join(' ', @defines)) if scalar @defines;

    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
    Apache::TestMM::generate_script('t/SMOKE');
};

my %modules;

if ($^O eq 'MSWin32') {
    eval 'use UUID 0.02;';
    eval 'use Win32::Guidgen 0.02;' if $@;
    eval 'use Win32API::GUID 0.02;' if $@;

    %modules = ('UUID' => 0.02) if $@;
} else {
    %modules = ('Data::UUID' => 0.10);
};

WriteMakefile(
    NAME         => 'Handel',
    VERSION_FROM => 'lib/Handel.pm',
    AUTHOR       => 'Christopher H. Laco <claco@chrislaco.com>',
    ABSTRACT     => 'Simple ecommerce framework with AxKit support',
    PREREQ_PM    => {
        'Class::DBI'       => '0.96',
        'DBI'              => '1.36',
        'Error'            => '0.14',
        'Locale::Maketext' => '1.06',
        %modules
    },
    (ExtUtils::MakeMaker->VERSION >= 6.11) ?
    (NO_META      => 1) : (),

    dist => {
        PREOP => '"pod2text ${DISTVNAME}/lib/Handel.pm > ${DISTVNAME}/README"',
    },
    clean => { FILES => 'smoke-report-* t/cart*.db t/TEST t/SMOKE t/logs t/htdocs/cart*.db' }
);
