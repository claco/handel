#!perl
# $Id$
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);