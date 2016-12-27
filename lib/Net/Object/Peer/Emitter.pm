# ABSTRACT: Peer-to-Peer Publish/Subscribe Network of Objects
package Net::Object::Peer::Emitter;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.03';

use Moo;
with 'BeamX::Peer::Emitter';

around subscribe => sub {

    my $orig = shift;

    push @_, class => 'Net::Object::Peer::Listener';

    &$orig;
};

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Emitter> object is used by L<Net::Object::Peer>
to manage outgoing communications with other nodes. It is derived from
L<BeamX::Peer::Emitter>.

