package Linux::Hosts::Entry;

##! A system hosts file entry.
##!
##! A valid entry contains a IPv4 / IPv6, an hostname and
##! an optional list of hostname aliases. The address and hostnames are
##! validated on creation or modification with following data validation
##! packages.
##!
##!  * [Data::Validate::IP](https://metacpan.org/pod/Data::Validate::IP)
##!  * [Data::Validate::Domain](https://metacpan.org/pod/Data::Validate::Domain)
##!
##! On failure an exception is thrown.

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Data::Validate::IP;
use Data::Validate::Domain;
use List::MoreUtils qw(uniq firstidx all);

subtype 'Address', as 'Str', where { is_ip($_) };

subtype 'Hostname', as 'Str', where { is_hostname($_) };

### IPv4 / IPv6 address.
has 'address' => (
    is       => 'ro',
    isa      => 'Address',
    required => 1,
);

### Canonical Hostname.
has 'hostname' => (
    is       => 'ro',
    isa      => 'Hostname',
    required => 1,
    writer   => '_set_hostname',
);

### List of aliases (hostnames).
###
### Attribute is not writeable on build. For manipulation see following
### methods.
###
### * add_alias
### * remove_alias
###
has 'aliases' => (
    is       => 'ro',
    isa      => 'ArrayRef[Hostname]',
    default  => sub { return [] },
    writer   => '_set_aliases',
    init_arg => undef,
);

### Add single or list of hostname aliases.
###
### Duplicates and aliases equal to hostname are removed.
sub add_alias {
    my ( $self, $aliases ) = @_;

    my @aliases = @{ $self->aliases };
    push @aliases, ref $aliases eq 'ARRAY' ? @{$aliases} : $aliases;
    @aliases = uniq @aliases;

    my $idx = firstidx { $_ eq $self->hostname } @aliases;
    splice @aliases, $idx, 1 if ( $idx != -1 );

    $self->_set_aliases( \@aliases );

    return;
}

### Remove single or list of hostname aliases.
###
### Not existing aliases are ignored.
sub remove_alias {
    my ( $self, $aliases ) = @_;

    my @aliases = @{ $self->aliases };

    if ( ref $aliases eq 'ARRAY' ) {
        for my $entry ( @{$aliases} ) {
            my $idx = firstidx { $_ eq $entry } @aliases;

            next if ( $idx == -1 );
            splice @aliases, $idx, 1;
        }
    }
    else {
        my $idx = firstidx { $_ eq $aliases } @aliases;

        splice @aliases, $idx, 1 if ( $idx >= 0 );
    }

    $self->_set_aliases( \@aliases );

    return;
}

### Set hostname.
sub set_hostname {
    my ( $self, $hostname ) = @_;

    $self->_set_hostname($hostname);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
