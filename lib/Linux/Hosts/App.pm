package Linux::Hosts::App;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;

use English qw(-no_match_vars);
use File::Which;
use Getopt::Long qw(:config require_order);
use IPC::Run;
use Path::Tiny;
use Pod::Usage;
use Text::Table;
use Term::ANSIColor;
use Term::ReadKey;
use Try::Tiny;

use Linux::Hosts;

no warnings 'uninitialized';

$Term::ANSIColor::AUTORESET = 1;

has 'action' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_action',
);

has 'options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_options',
);

has 'hosts' => (
    is      => 'ro',
    isa     => 'Linux::Hosts',
    lazy    => 1,
    builder => '_build_hosts',
);

sub _build_action {
    my $self = shift;

    $self->options;

    my $action = $ARGV[0] || '';
    $action =~ s/-/_/g;

    $action ||= 'list';

    return $action;
}

sub _build_options {
    my $self = shift;

    my %options;
    GetOptions(
        "help|h"    => \$options{'help'},
        "man|m"     => \$options{'man'},
        "version|v" => \$options{'version'},
        "no-legend" => \$options{'no_legend'},
        "no-pager"  => \$options{'no_pager'},
    ) or exit $self->usage();

    foreach my $key ( keys %options ) {
        delete $options{$key} if ( !$options{$key} );
    }

    $options{'count'} = keys %options;

    return \%options;
}

sub _build_hosts {
    my $self = shift;

    return Linux::Hosts->new();
}

sub help {
    my $self = shift;

    pod2usage(
        -exitval  => 'NOEXIT',
        -verbose  => 99,
        -input    => __FILE__,
        -sections => 'SYNOPSIS|OPTIONS|PARAMETERS',
    );

    return 0;
}

sub man {
    my $self = shift;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 2,
        -input   => __FILE__,
    );

    return 0;
}

sub usage {
    my $self = shift;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 0,
        -input   => __FILE__,
    );

    return 255;
}

sub version {
    my $self = shift;

    printf "hostsctl %s\n", $Linux::Hosts::VERSION;

    return 0;
}

sub print_output {
    my ( $self, $output ) = @_;

    my ( $width, $height ) = GetTerminalSize();
    my $num = scalar split "\n", $output;

    my $pager = $ENV{'PAGER'};
    if ( !$pager || !File::Which::which($pager) ) {
        for (qw(less more)) {
            $pager = File::Which::which($_);
            last if ($pager);
        }
    }

    if (   $self->options->{'no_pager'}
        || !$pager
        || ( $height > $num ) )
    {
        print $output;
    }
    else {
        my $tmpfile = Path::Tiny::tempfile();
        $tmpfile->spew($output);
        IPC::Run::run( [ 'sh', '-c', $pager . ' < ' . $tmpfile->stringify ] );
    }

    return;
}

sub do_list {
    my $self = shift;

    my @entries = $self->hosts->list;

    my $table = Text::Table->new( "ADDRESS", "HOSTNAME", "ALIAS" );

    for my $entry (@entries) {
        my $aliases = join ' ', @{ $entry->aliases };

        $table->load( [ $entry->address, $entry->hostname, $aliases || '' ] );
    }

    my $length = length $table->title;
    my $num    = scalar @entries;

    my $output;

    $output .= $table->title . '—' x $length . "\n"
      if ( !$self->options->{'no_legend'} );

    $output .= $table->body;

    $output .= "\n" . $num . " entries listed.\n"
      if ( !$self->options->{'no_legend'} );

    $self->print_output($output);

    return 0;
}

sub do_method {
    my ( $self, $method, @args ) = @_;

    my $rc = try {
        $self->hosts->$method(@args);
        return 0;
    }
    catch {
        printf {*STDERR} "%s\n", colored( $_->message . '.', 'bold red' );
        return $_->errno;
    };

    return $rc;
}

sub do_add {
    my $self = shift;

    my ( $address, $hostname, $aliases ) = @ARGV;
    return $self->usage() if ( !$address || !$hostname );

    my @aliases = split ',', $aliases;

    return $self->do_method( 'add', ( $address, $hostname, \@aliases ) );
}

sub do_remove {
    my $self = shift;

    my $address = shift @ARGV;
    return $self->usage() if ( !$address );

    return $self->do_method( 'remove', ($address) );
}

sub do_set_hostname {
    my $self = shift;

    my ( $address, $hostname ) = @ARGV;
    return $self->usage() if ( !$address || !$hostname );

    return $self->do_method( 'set_hostname', ( $address, $hostname ) );
}

sub do_add_alias {
    my $self = shift;

    my ( $address, $aliases ) = @ARGV;
    return $self->usage() if ( !$address || !$aliases );

    my @aliases = split ',', $aliases;

    return $self->do_method( 'add_alias', ( $address, \@aliases ) );
}

sub do_remove_alias {
    my $self = shift;

    my ( $address, $aliases ) = @ARGV;
    return $self->usage() if ( !$address || !$aliases );

    my @aliases = split ',', $aliases;

    return $self->do_method( 'remove_alias', ( $address, \@aliases ) );
}

sub run {
    my $self = shift;

    $self = Linux::Hosts::App->new() if ( !Scalar::Util::blessed($self) );

    return $self->usage()
      if (
        (
               $self->options->{'help'}
            || $self->options->{'man'}
            || $self->options->{'version'}
        )
        && $self->options->{'count'} > 1
      );
    return help()    if ( $self->options->{'help'} );
    return man()     if ( $self->options->{'man'} );
    return version() if ( $self->options->{'version'} );

    my %METHOD = (
        list         => 'do_list',
        add          => 'do_add',
        remove       => 'do_remove',
        set_hostname => 'do_set_hostname',
        add_alias    => 'do_add_alias',
        remove_alias => 'do_remove_alias',
    );
    my $method = $METHOD{ $self->action };
    return $self->usage() if ( !$method );

    shift @ARGV;

    return $self->$method;
}

__PACKAGE__->meta->make_immutable;

1;

## no critic (Documentation)

__END__

=encoding utf8

=head1 NAME

hostsctl - Query and control the system hosts file.

=head1 SYNOPSIS

hostsctl --help|-h | --man|-m | --version|-v

hostsctl [--no-legend] [--no-pager] list

hostsctl add ADDRESS HOSTNAME [ALIASES] | remove ADDRESS

hostsctl set-hostname ADDRESS HOSTNAME

hostsctl add-alias ADDRESS ALIASES | remove-alias ADDRESS ALIASES

=head1 OPTIONS

=head2 base

=over 8

=item --help|-h

Print short usage help.

=item --man|-m

Print extended usage help.

=item --version|-v

Print version string.

=back

=head2 list

=over 8

=item --no-legend

Do not print a legend (column headers and hints).

=item --no-pager

Do not pipe output into a pager.

=back

=head1 PARAMETERS

=over 8

=item list

List all hosts entries tabular formatted with info about number of entries.

=item add ADDRESS HOSTNAME [ALIASES]

Add new hosts entry for given ADDRESS and HOSTNAME. Add optional comma
seperated ALIASES.

=item remove ADDRESS

Remove hosts entry by ADDRESS.

=item set-hostname ADDRESS HOSTNAME

Set canonical hostname of hosts entry by ADDRESS.

=item add-alias ADDRESS ALIASES

Add comma seperated ALIASES from hosts entry by ADDRESS,

=item remove-alias ADDRESS ALIASES

Remove comma seperated ALIASES from hosts entry by ADDRESS,

=back

=head1 DESCRIPTION

hostsctl may be used to query and change the system hosts file (L<man 5 hosts>).

=cut
