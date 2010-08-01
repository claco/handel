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

requires 'DBIx::Class'              => '0.08123';
requires 'DBIx::Class::UUIDColumns' => '0.02005';
requires 'DBIx::Class::Validation'  => '0.02005';
requires 'Data::Currency'           => '0.04002';
requires 'Class::Accessor::Grouped' => '0.09003';
requires 'Class::ISA'               => '0.36';
requires 'Class::Inspector'         => '1.24';
requires 'Clone'                    => '0.31';
requires 'Error'                    => '0.17016';
requires 'Carp';
requires 'Locale::Maketext'         => '1.13';
requires 'Module::Pluggable'        => '3.9';
requires 'Module::Starter'          => '1.54';
requires 'Scalar::Util'             => '1.22';
requires 'Tie::Hash'                => '1.03';
requires 'DateTime'                 => '0.61';
requires 'DateTime::Format::MySQL'  => '0.04';
requires 'Locale::Currency'         => '2.07';
requires 'Locale::Currency::Format' => '1.28';
requires 'FormValidator::Simple'    => '0.28';
requires 'Finance::Currency::Convert::WebserviceX' => '0.07001';
requires 'NEXT'                     => '0.64';
requires 'FileHandle'               => '2.01';
requires 'File::Spec::Functions'    => '3.3';
requires 'File::Path'               => '2.08';
requires 'SQL::Translator'          => '0.11006';
requires 'Getopt::Long'             => '2.38';
requires 'Pod::Usage'               => '1.36';
requires 'DBD::SQLite'              => '1.29';
requires 'Data::Currency'           => '0.04002';
build_requires 'Test::More' => '0.94';

feature 'Catalyst Support',
  -default => 0,
  'Catalyst::Runtime'               => '5.80025',
  'Catalyst::Devel'                 => '1.28',
  'Catalyst::View::TT'              => '0.34',
  'Catalyst::Plugin::Session'       => '0.3',
  'Catalyst::Plugin::Session::Store::File'      => '0.18',
  'Catalyst::Plugin::Session::State::Cookie'    => '0.17',
  'YAML'                => '0.71',
  'HTML::FillInForm'    => '2.00';

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
