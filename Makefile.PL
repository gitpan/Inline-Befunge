# This -*- perl -*- script writes the Makefile for Language::Befunge
# $Id: Makefile.PL,v 1.5 2002/04/16 15:43:33 jquelin Exp $

use strict;
use ExtUtils::MakeMaker;

# Check for non-standard modules that are used by this library.
$| = 1;
my $missing_modules = 0;


print "Checking for Inline..............";
eval {
    require Inline;
    Inline->VERSION(0.43);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The Inline module must be installed. How do you want me to parse
inlined subroutines if you don't provide me with this so cool module?

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for Language::Befunge...";
eval {
    require Language::Befunge;
    Language::Befunge->VERSION(0.35);
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The Language::Befunge module must be installed. I _really_ need it to
interpret the Befunge code!

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

# Warn user.
print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN.  Visit
<URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT

print "\n";


WriteMakefile(
    NAME          => 'Inline::Befunge',
    VERSION_FROM  => 'Befunge.pm',
    PREREQ_PM	  => { Inline => 0.43, Language::Befunge => 0.35 },
    clean         => { FILES => "*~ t/*~ MANIFEST.bak _Inline" },
    ABSTRACT_FROM => 'Befunge.pm',
    AUTHOR        => 'Jerome Quelin, <jquelin@cpan.org>',
);
