#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'   => 'Query and control the system hosts file.',
    'AUTHOR'     => 'Tobias Schaefer <github@blackox.org>',
    'DISTNAME'   => 'Linux-Hosts',
    'EXE_FILES'  => ['bin/hostsctl'],
    'META_MERGE' => {
        resources => {
            'license'    => 'http://dev.perl.org/licenses',
            'homepage'   => 'https://github.com/tschaefer/linux-hosts',
            'repository' => 'https://github.com/tschaefer/linux-hosts.git',
        }
    },
    'NAME'      => 'Linux::Hosts',
    'PREREQ_PM' => {
        'Data::Validate::Domain' => '0.14',
        'Data::Validate::IP'     => '0.27',
        'IPC::Run'               => '20200505.0',
        'List::MoreUtils'        => '0.430',
        'Moose'                  => '2.2014',
        'Path::Tiny'             => '0.114',
        'Readonly'               => '2.05',
        'Term::ANSIColor'        => '5.01',
        'Term::ReadKey'          => '2.38',
        'Text::Table'            => '1.134',
        'Throwable'              => '0.200013',
        'Try::Tiny'              => '0.30',
    },
    'VERSION_FROM' => 'lib/Linux/Hosts.pm',
    'clean'        => { FILES    => 'Linux-Hosts-*' },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
);
