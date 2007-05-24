#!perl
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
	module_name         => 'Inline::Befunge',
	license             => 'gpl',
    dist_version_from   => 'lib/Inline/Befunge.pm',
    add_to_cleanup => [
                'Inline-Befunge-*', '_Inline',
                map { ( '*/' x $_ ) . '*~' } 0..3 ],
    build_requires => { },
    requires => {
        'Inline'            => '0.43',
        'Language::Befunge' => '0.36',
    },
);

$builder->create_build_script();
