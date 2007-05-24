#!perl
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Inline::Befunge',
    AUTHOR              => 'Jerome Quelin <jquelin@cpan.org>',
    VERSION_FROM        => 'lib/Inline/Befunge.pm',
    ABSTRACT_FROM       => 'lib/Inline/Befunge.pm',
    PL_FILES            => {},
    PREREQ_PM => {
		'Inline'            => '0.43',
		'Language::Befunge' => '0.36',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [
                'Inline-Befunge-*', '_Inline',
                map { ( '*/' x $_ ) . '*~' } 0..3
                ] },
);
