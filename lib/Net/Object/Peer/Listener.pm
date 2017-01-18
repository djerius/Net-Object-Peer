# ABSTRACT: Net::Object::Peer specfic Listener
package Net::Object::Peer::Listener;

use 5.10.0;

use Types::Standard 'ConsumerOf';

use Moo;
use strictures 2;
use namespace::clean;
extends 'BeamX::Peer::Listener';

our $VERSION = '0.04';

has +peer => (
    is  => 'ro',
    isa => ConsumerOf ['Net::Object::Peer'],
    weak_ref => 1,
);

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::Listener> is a sub-class of L<BeamX::Peer::Listener>,
which adds the requirement that the peer be a consumer of L<Net::Object::Peer>.

Listener classes used with L<Net::Object::Peer> must be derived from
this class.
