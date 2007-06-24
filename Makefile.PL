# $Id$
use ExtUtils::MakeMaker;
use 5.008001;
use strict;
use warnings FATAL => 'all';

require Test::More;
if (Test::More->VERSION < 0.60) {
    print "\a\a\a\a\a";
    print "----------------------------------------------------------\n";
    print "Test::More < 0.61 sometimes causes test failures with\n";
    print "when comparing strigified DateTime objects.\n";
    print "Please consider updating Test::More to version 0.61\n";
    print "or greater if you experience test failures.\n";
    print "----------------------------------------------------------\n";
    sleep 5;
};

#eval 'require Handel';
#if (!$@ && $Handel::VERSION <= '1.00') {
#    print "\a\a\a\a\a";
#    print "----------------------------------------------------------\n";
#    print "BREAKING API CHANGES!!!!\n\n";
#    print "Handel 1.0+ is not API compatable with Handel <= 0.32.\n";
#    print "Please read the documentation for further details.\n";
#    print "----------------------------------------------------------\n";
#    sleep 5;
#};

if ($ENV{TEST_HTTP}) {
    eval 'use Apache::Test 1.27';
    if ($@) {
        print "Apache-Test >= 1.27 is required!\n";
    } else {
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
} else {
    print 'Set TEST_HTTP to enable Apache-Test/HTTP tests', "\n";
};

my @clean = qw(
    smoke-report-*
    t/TEST
    t/SMOKE
    t/logs
    t/conf/apache_test_config.pm
    t/conf/extra.conf
    t/conf/httpd.conf
    t/conf/modperl_inc.pl
    t/conf/modperl_startup.pl
    t/htdocs/index.html
    t/var
);

WriteMakefile(
    NAME         => 'Handel',
    VERSION_FROM => 'lib/Handel.pm',
    AUTHOR       => 'Christopher H. Laco <claco@chrislaco.com>',
    ABSTRACT     => 'A cart/order/checkout framework with AxKit/TT/Catalyst support',
    PREREQ_PM    => {
        'DBIx::Class'              => '0.08000',
        'DBIx::Class::UUIDColumns' => '0.01',
        'DBIx::Class::Validation'  => '0.01001',
        'Data::Currency'           => '0.03',
        'Class::Accessor::Grouped' => '0.03',
        'Class::ISA'               => '0',
        'Class::Inspector'         => '0',
        'Clone'                    => '0',
        'Error'                    => '0.14',
        'Locale::Maketext'         => '1.06',
        'Module::Pluggable'        => '3.1',
        'Module::Starter'          => '1.42',
        'Scalar::Util'             => '0',
        'Tie::Hash'                => '0',
        'DateTime'                 => '0',
        'DateTime::Format::MySQL'  => '0',
        'Locale::Currency'         => '2.07',
        'Locale::Currency::Format' => '1.22',
        'FormValidator::Simple'    => '0.17',
        'Finance::Currency::Convert::WebserviceX' => '0.03',
        'NEXT'                     => '0',
        'FileHandle'               => '0',
        'File::Spec::Functions'    => '0',
        'File::Path'               => '0',
        'SQL::Translator'          => '0.08',
        'Getopt::Long'             => '0',
        'Pod::Usage'               => '0',
        'DBD::SQLite'              => '0',
    },
    EXE_FILES => [
        'script/handel.pl'
    ],
    NO_META => 1,
    dist => {
        PREOP => 'pod2text lib/Handel.pm > $(DISTVNAME)/README',
    },
    clean => { FILES => join ' ', @clean }
);
