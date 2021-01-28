package Linux::Hosts::Exception;

##! Simple generic exception class.
##!
##! Exception object contains two attributes.
##!
##!  * *message*, short error description
##!  * *errno*, suitable system error number
##!
##! Exception is thrown on failure in [Linux:Hosts](../Hosts.html).
##!
##! For further info see `man 3 errno`.

use strict;
use warnings;

use Moose;
with qw(Throwable);

use Errno qw(:POSIX);

### Short error description.
has 'message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### System error number.
has 'errno' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_set_errno',
);

### Determine system error number by message.
sub BUILD {
    my $self = shift;

    my %errors = (
        qr/no such/i => &Errno::ENOENT,
        qr/denied/i  => &Errno::EACCES,
        qr/exists/i  => &Errno::EEXIST,
        qr/invalid/i => &Errno::EINVAL,
    );
    my $errno = 255;
    while ( my ( $regex, $num ) = each %errors ) {
        if ( $self->message =~ $regex ) {
            $errno = $num;
            last;
        }
    }

    $self->_set_errno($errno);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
