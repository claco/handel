#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 19;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout', 'Handel::Checkout::Stash');
&run('Handel::Subclassing::Checkout', 'Handel::Checkout::Stash');
&run('Handel::Subclassing::CheckoutStash', 'Handel::Subclassing::Stash');

sub run {
    my ($subclass, $stashclass) = @_;


    ## Check the default stash creation
    {
        my $checkout = $subclass->new;
        isa_ok($checkout->stash, $stashclass);
    };


    ## Check the stash parameter
    {
        my $stash = CustomStash->new;
        my $checkout = Handel::Checkout->new({
            stash => $stash
        });

        isa_ok($checkout->stash, 'CustomStash');
        isa_ok($checkout->stash, 'Handel::Checkout::Stash');
    };


    ## Check stash_class
    {
        Handel::Checkout->stash_class('CustomStash');

        my $checkout = Handel::Checkout->new;

        isa_ok($checkout->stash, 'CustomStash');
        isa_ok($checkout->stash, 'Handel::Checkout::Stash');
    };

};


package CustomStash;
use strict;
use warnings;
use base 'Handel::Checkout::Stash';

1;

