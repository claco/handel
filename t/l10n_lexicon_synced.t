#!perl -w
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Module::Find';
    if($@) {
        plan skip_all => 'Module::Find not installed';
    } else {
        plan tests => 265;
        setmoduledirs('lib');
    };

    use_ok('Handel::L10N::en_us');
};


no strict 'refs';
no warnings 'once';

my $primary = \%Handel::L10N::en_us::Lexicon;

my @lexicons = findallmod('Handel::L10N');
foreach my $lex (@lexicons) {
    if ($lex =~ /^(Handel::L10N::.*)$/) {
        $lex = $1;
    } else {
        next;
    };

    eval "require $lex";
    my $entries = \%{"$lex\:\:Lexicon"};

    ## make sure our counts match
    is(scalar keys %{$primary}, scalar keys %{$entries}, "$lex has differing number of entries");


    ## make sure all the entries are actually there
    foreach my $entry (keys %{$primary}) {
        ok(exists $entries->{$entry}, "No entry found for $entry in $lex");
    };
};
