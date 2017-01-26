# ABSTRACT: The payload for a Net::Object::Peer unsubscription event

package Net::Object::Peer::UnsubscribeEvent;

use 5.10.0;

use Types::Standard qw[ ArrayRef Str is_ArrayRef ];

use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '0.07';

extends 'Net::Object::Peer::Event';

=attr event_names

=cut

has event_names => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => '%all%',
    coerce  => sub { is_ArrayRef( $_[0] ) ? $_[0] : [ $_[0] ] },
);

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::UnsubscribeEvent> is sent to a subscriber of
a peer's C<unsubscribe> event.  It is derived from L<Net::Object::Peer::Event>.

