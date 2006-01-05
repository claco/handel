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
    print "with 'attempt to free unreferenced scalar' errors.\n";
    print "----------------------------------------------------------\n";
    sleep 5;
};

eval 'require Handel';
if (!$@ && Handel->VERSION eq '0.17') {
    print "\a\a\a\a\a";
    print "----------------------------------------------------------\n";
    print "BREAKING API CHANGES!!!!\n\n";
    print "Handel::Order >= 0.18 is incompatable with Handel::Order\n";
    print "version 0.17 only. Earlier versions of Handel without\n";
    print "Handel::Order are not effected.\n";
    print "----------------------------------------------------------\n";
    sleep 5;
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
if ($^O ne 'openbsd' && eval {require APR::UUID}) {
    %modules = ();
};

if ($ENV{TEST_HTTP}) {
    eval 'use Apache::Test 1.27';
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
} else {
    print 'Set TEST_HTTP to enable Apache-Test/HTTP tests', "\n";
};

my @clean = qw(
    smoke-report-*
    t/cart*.db
    t/order*.db
    t/checkout*.db
    t/subclassing.db
    t/TEST
    t/SMOKE
    t/logs
    t/htdocs/*.db
    t/TestApp
    t/conf/apache_test_config.pm
    t/conf/extra.conf
    t/conf/httpd.conf
    t/conf/modperl_inc.pl
    t/conf/modperl_startup.pl
    t/htdocs/index.html
);

WriteMakefile(
    NAME         => 'Handel',
    VERSION_FROM => 'lib/Handel.pm',
    AUTHOR       => 'Christopher H. Laco <claco@chrislaco.com>',
    ABSTRACT     => 'Simple ecommerce framework with AxKit support',
    PREREQ_PM    => {
        'Class::DBI'        => '0.96',
        'Class::Data::Inheritable' => '0',
        'DBI'               => '1.36',
        'Error'             => '0.14',
        'Locale::Maketext'  => '1.06',
        'Module::Pluggable' => '2.95',
        'version'           => '0',
        %modules
    },
    (ExtUtils::MakeMaker->VERSION >= 6.11) ?
    (NO_META      => 1) : (),

    dist => {
        PREOP => 'pod2text lib/Handel.pm > $(DISTVNAME)/README',
    },
    clean => { FILES => join ' ', @clean },
    test  => { TESTS => join ' ', (glob("t/*.t"))}
);
