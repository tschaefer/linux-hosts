package Linux::Hosts;

##! Query and change system hosts file.
##!
##! * list entries [Linux::Hosts::Entry](Hosts/Entry.html)
##! * add entry
##! * remove entry
##! * set hostname, add or remove hostname aliases of existing entry
##!
##! All methods throw an exception
##! [Linux::Hosts::Exception](Hosts/Exception.html) on failure.
##!
##! * attribute validation
##! * missing or already existing entry
##! * read, write permission
##!
##! For further information see `man 5 hosts`.

use strict;
use warnings;

use Moose;

use Carp qw(croak);
use English qw(-no_match_vars);
use Path::Tiny;
use Readonly;
use Text::Table;
use Try::Tiny;

use Linux::Hosts::Entry;
use Linux::Hosts::Exception;

our $VERSION = '1.000';

no warnings 'uninitialized';

### Hash of entries with address as identifier.
has 'entries' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_entries',
);

Readonly::Scalar my $PATH => '/etc/hosts';

### Throw exception.
###
### Determine error number by given message.
sub _throw {
    my ( $self, $message ) = @_;

    Linux::Hosts::Exception->new( message => $message )->throw();

    return;
}

### Read hosts file and set *entries* attribute.
sub _build_entries {
    my $self = shift;

    my $text =
      try { path($PATH)->slurp; } catch { $self->_throw( $_->{'err'} ); };

    my %entries;

    for my $line ( split /\n/, $text ) {
        next if ( $line =~ /\s*#/ );
        next if ( $line =~ /^\s*$/ );

        my ( $address, $hostname, $aliases ) = split /\s+/, $line, 3;
        next if ( $hostname =~ /^#/ );
        my @aliases = undef;
        @aliases = split /\s+/, $aliases if ( $aliases && $aliases !~ /^#/ );

        if ( !$entries{$address} ) {
            my $entry = try {
                Linux::Hosts::Entry->new(
                    address  => $address,
                    hostname => $hostname,
                );
            };
            next if ( !$entry );

            try { $entry->add_alias( \@aliases ) if ( $aliases[0] ); };
            $entries{$address} = $entry;
        }
        else {
            try {
                $entries{$address}->add_alias($hostname);
                $entries{$address}->add_alias( \@aliases ) if ( $aliases[0] );
            };
        }
    }

    return \%entries;
}

### Write formatted entries to hosts file.
###
###     127.0.0.1     localhost
###     127.0.1.1     stretch.u.mesh.io stretch.local stretch
###     192.168.0.200 core.u.mesh.io    core.local core music.local music
###     ...
sub _spew_formatted {
    my $self = shift;

    my @entries = $self->list;

    my $table = Text::Table->new();
    for my $entry (@entries) {
        my $aliases = join ' ', @{ $entry->aliases };

        $table->load( [ $entry->address, $entry->hostname, $aliases || '' ] );
    }
    my $body = $table->body;
    $body =~ s/\s+$//gm;
    $body .= "\n";

    my $header = "# hosts(5) file generated by hostsctl(1)\n\n";

    my $content = $header . $body;

    try { path($PATH)->spew($content); } catch { $self->_throw( $_->{'err'} ); };

    return;
}

### Return list of entries sorted by address.
sub list {
    my $self = shift;

    my @entries =
      sort { $a->address cmp $b->address } values %{ $self->entries };

    return @entries;
}

### Add hosts entry defined by following attributes.
###
### * IPv6 / IPv4 address
### * hostname
### * list of aliases (optional)
###
sub add {
    my ( $self, $address, $hostname, $aliases ) = @_;

    my $entries = $self->entries;
    $self->_throw('Entry exists') if ( $entries->{$address} );

    my $entry;
    try {
        $entry = Linux::Hosts::Entry->new(
            address  => $address,
            hostname => $hostname,
        );
        $entry->add_alias($aliases) if ($aliases);
    }
    catch {
        $self->_throw( sprintf "Invalid %s", $_->attribute_name );
    };
    $entries->{$address} = $entry;

    $self->_spew_formatted();

    return;
}

### Remove entry by address.
sub remove {
    my ( $self, $address ) = @_;

    my $entries = $self->entries;
    $self->_throw('No such entry') if ( !$entries->{$address} );

    delete $entries->{$address};
    $self->_spew_formatted($entries);

    return;
}

### Set canonical hostname of existing entry.
sub set_hostname {
    my ( $self, $address, $hostname ) = @_;

    my $entries = $self->entries;
    $self->_throw('No such entry') if ( !$entries->{$address} );

    try {
        $entries->{$address}->set_hostname($hostname);
    }
    catch {
        $self->_throw('Invalid hostname');
    };
    $self->_spew_formatted($entries);

    return;
}

### Add single or list of hostname aliases of existing entry.
sub add_alias {
    my ( $self, $address, $aliases ) = @_;

    my $entries = $self->entries;
    $self->_throw('No such entry') if ( !$entries->{$address} );

    try {
        $entries->{$address}->add_alias($aliases);
    }
    catch {
        $self->_throw('Invalid alias');
    };
    $self->_spew_formatted($entries);

    return;
}

### Remove single or list of hostname aliases of existing entry.
sub remove_alias {
    my ( $self, $address, $aliases ) = @_;

    my $entries = $self->entries;
    $self->_throw('No such entry') if ( !$entries->{$address} );

    try {
        $entries->{$address}->remove_alias($aliases);
    }
    catch {
        $self->_throw('Invalid alias');
    };
    $self->_spew_formatted($entries);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
