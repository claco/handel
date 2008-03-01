# $Id$
use strict;
use warnings FATAL => 'all';
use inc::Module::Install 0.65;

if ($ENV{TEST_HTTP}) {
    eval 'use Apache::Test 1.27';
    if ($@) {
        print "Apache-Test >= 1.27 is required!\n";
        tests 't/*.t';
    } else {
        tests join(' ', glob('t/*.t'));

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
    tests 't/*.t';
};

name 'Handel';
license 'perl';
perl_version '5.008001';
all_from 'lib/Handel.pm';

requires 'DBIx::Class'              => '0.08008';
requires 'DBIx::Class::UUIDColumns' => '0.02000';
requires 'DBIx::Class::Validation'  => '0.02000';
requires 'Data::Currency'           => '0.04002';
requires 'Class::Accessor::Grouped' => '0.03';
requires 'Class::ISA';
requires 'Class::Inspector';
requires 'Clone' => '0.28';
requires 'Error'                    => '0.14';
requires 'Locale::Maketext'         => '1.06';
requires 'Module::Pluggable'        => '3.1';
requires 'Module::Starter'          => '1.42';
requires 'Scalar::Util';
requires 'Tie::Hash';
requires 'DateTime';
requires 'DateTime::Format::MySQL';
requires 'Locale::Currency'         => '2.07';
requires 'Locale::Currency::Format' => '1.22';
requires 'FormValidator::Simple'    => '0.17';
requires 'Finance::Currency::Convert::WebserviceX' => '0.03';
requires 'NEXT';
requires 'FileHandle';
requires 'File::Spec::Functions';
requires 'File::Path';
requires 'SQL::Translator'          => '0.08';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'DBD::SQLite';
build_requires 'Test::More' => '0.61';

feature 'Catalyst Support',
  -default => 0,
  'Catalyst::Runtime' => '5.7007',
  'Catalyst::Devel' => '1.02',
  'Catalyst::View::TT' => 0,
  'Catalyst::Plugin::Session',
  'Catalyst::Plugin::Session::Store::File',
  'Catalyst::Plugin::Session::State::Cookie',
  'YAML' => '0.65',
  'HTML::FillInForm' => '1.05';

feature 'AxKit Support',
  -default                   => 0,
  'AxKit' => '1.61';

install_script 'script/handel.pl';

clean_files 'smoke-report-* t/var Handel-* t/TEST t/SMOKE t/logs t/conf/apache_test_config.pm t/conf/extra.conf t/conf/httpd.conf t/conf/modperl_inc.pl t/conf/modperl_startup.pl t/htdocs/index.html t/var';

eval {
    system 'pod2text lib/Handel.pm > README';
};

auto_install;
WriteAll;
