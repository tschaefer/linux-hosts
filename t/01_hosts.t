## no critic
no warnings 'redefine';

use Test::More;
use Test::MockFile;
use Test::Exception;

BEGIN {
    *CORE::GLOBAL::flock = sub { return 1; };
}

use Path::Tiny;
use Linux::Hosts;

my $SpewOutput;
local *Path::Tiny::spew = sub { shift @_; $SpewOutput = $_[0]; };

my $MockFile = Test::MockFile->file( '/etc/hosts', '127.0.0.1 localhost' );

note("Create object (read '/etc/hosts').");
my $Hosts   = Linux::Hosts->new();
my @Entries = $Hosts->list();
is( scalar @Entries,       1,           'Hosts entry count is 1.' );
is( $Entries[0]->hostname, 'localhost', "Hostname is 'localhost'." );
is( $Entries[0]->address,  '127.0.0.1', "Address is '127.0.0.1'." );

note("Add host entry.");
$Hosts->add( '127.0.1.1', 'localhorst', [ 'home', 'happyplace' ] );
@Entries = $Hosts->list();
is( scalar @Entries,       2,            'Hosts entry count is 2.' );
is( $Entries[0]->hostname, 'localhost',  "Hostname is 'localhost'." );
is( $Entries[0]->address,  '127.0.0.1',  "Address is '127.0.0.1'." );
is( $Entries[1]->hostname, 'localhorst', "Hostname is 'localhorst'." );
is( $Entries[1]->address,  '127.0.1.1',  "Address is '127.0.1.1'." );
is_deeply( $Entries[1]->aliases, [ 'home', 'happyplace' ], 'Aliases found.' );

note("Set hostname.");
$Hosts->set_hostname( '127.0.1.1', 'myplace' );
@Entries = $Hosts->list();
is( scalar @Entries,       2,           'Hosts entry count is 2.' );
is( $Entries[0]->hostname, 'localhost', "Hostname is 'localhost'." );
is( $Entries[0]->address,  '127.0.0.1', "Address is '127.0.0.1'." );
is( $Entries[1]->hostname, 'myplace',   "Hostname is 'myplace'." );
is( $Entries[1]->address,  '127.0.1.1', "Address is '127.0.1.1'." );
is_deeply( $Entries[1]->aliases, [ 'home', 'happyplace' ], 'Aliases found.' );

note("Add alias.");
$Hosts->add_alias( '127.0.1.1', 'cup' );
@Entries = $Hosts->list();
is_deeply( $Entries[1]->aliases, [ 'home', 'happyplace', 'cup' ], 'Aliases found.' );

note("Remove alias.");
$Hosts->remove_alias( '127.0.1.1', [ 'cup' ] );
@Entries = $Hosts->list();
is_deeply( $Entries[1]->aliases, [ 'home', 'happyplace' ], 'Aliases found.' );

note('Linux::Hosts::Exception.');
throws_ok( sub { $Hosts->add( 'address', 'exception.address' ) },
    'Linux::Hosts::Exception', 'Bad address.' );
throws_ok( sub { $Hosts->add( '172.16.0.111', 'bäd.hostname' ) },
    'Linux::Hosts::Exception', 'Bad hostname.' );
throws_ok( sub { $Hosts->add( '127.0.1.1', 'duplicated.address' ) },
    'Linux::Hosts::Exception', 'Duplicated address.' );
throws_ok( sub { $Hosts->add_alias( '127.0.0.1', 'bäd.alias' ) },
    'Linux::Hosts::Exception', 'Bad alias.' );

note("Add host entry with v6 address.");
$Hosts->add( '::1', 'localhost' );
@Entries = $Hosts->list('ipv6');
is( scalar @Entries,       1,           'Ipv6 hosts entry count is 1.' );
is( $Entries[0]->hostname, 'localhost', "Hostname is 'localhost'." );
is( $Entries[0]->address,  '::1',       "Address is '::1'." );
@Entries = $Hosts->list('ipv4');
is( scalar @Entries, 2, 'Ipv4 hosts entry count is 2.' );

done_testing();
