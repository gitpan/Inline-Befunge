#-*- cperl -*-
# $Id: 01basic.t,v 1.2 2002/04/16 15:47:10 jquelin Exp $
#

#-------------------------------#
#          The basics.          #
#-------------------------------#

use strict;
use Inline "Befunge";
use Test;

# Vars.
my $tests;
BEGIN { $tests = 0 };

# Basic loading.
ok(1);
BEGIN { $tests +=1 };

BEGIN { plan tests => $tests };


__END__
__Befunge__
;:foo; < q,,,,"foo"a
