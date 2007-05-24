#!perl
#
# This file is part of Inline::Befunge.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#


#-------------------------------------#
#          Subroutine calls.          #
#-------------------------------------#

use strict;
use Inline "Befunge";
use Test;

# Vars.
my $tests;
BEGIN { $tests = 0 };

# Test various subs.
ok( return4(), 4 );
ok( bf_cmp(2,4), -1 );
ok( bf_cmp(2,2), 0 );
ok( bf_cmp(2,1), 1 );
BEGIN { $tests += 4 };

# String mode.
use Inline BEF => <<'END_OF_CODE';
019p >    :             #v _ v ;:bf_reverse;
@    ^ p91 +1 g91 p8 g91 <   $
|       ` g91 g92  <    p920 <
> 29g 8g 29g 1+29p ^
END_OF_CODE
ok( join "", map {chr} bf_reverse( "foobar" ) eq "raboof" );
BEGIN { $tests += 1 };


BEGIN { plan tests => $tests };

__END__
__Befunge__
;:return4;4q
   ;
   :
   b
   f
   _
   c
   m
   p
   ;
   v
q1 w 01-
   0
   q
