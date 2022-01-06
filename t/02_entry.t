## no critic
use Test::More;
use Test::Exception;

use Linux::Hosts::Entry;

note('Create objects.');
for my $address (qw(127.0.0.1 ::1)) {
    my $Entry = Linux::Hosts::Entry->new(
        address  => $address,
        hostname => 'localhorst',
    );
    is( $Entry->hostname, 'localhorst', "Hostname is 'localhorst'." );
    is( $Entry->address, $address, sprintf "Address is '%s'.", $address );
}

note('Add aliases.');
my $Entry = Linux::Hosts::Entry->new(
    address  => '127.0.0.1',
    hostname => 'localhorst',
);
$Entry->add_alias( [ 'home', 'happyplace' ] );
is_deeply( $Entry->aliases, [ 'home', 'happyplace' ], 'Aliases found.' );

note('Linux::Hosts::Exception.');
throws_ok(
    sub {
        Linux::Hosts::Entry->new(
            address  => 'address',
            hostname => 'bad.address'
        );
    },
    'Moose::Exception',
    'Bad address.'
);
throws_ok(
    sub {
        Linux::Hosts::Entry->new(
            address  => '127.0.0.1',
            hostname => 'bäd.hostname'
        );
    },
    'Moose::Exception',
    'Bad hostname.'
);
throws_ok(
    sub {
        Linux::Hosts::Entry->new(
            address  => '127.0.0.1',
            hostname => 'bäd.hostname'
        );
    },
    'Moose::Exception',
    'Bad hostname.'
);
throws_ok(
    sub {
        $Entry->add_alias('bäd.alias');
    },
    'Moose::Exception',
    'Bad alias.'
);

done_testing();
