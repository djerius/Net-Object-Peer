# ABSTRACT: Net::Object::Peer specfic Listener
package Net::Object::Peer::Listener;

use 5.10.0;
use strict;
use warnings;

our $VERSION = "0.01";

use Types::Standard 'ConsumerOf';
use namespace::clean;

use Moo;
extends 'BeamX::Peer::Listener';


has +peer => (
    is  => 'ro',
    isa => ConsumerOf ['Net::Object::Peer'],
);

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::Listener> is a sub-class of L<BeamX::Peer::Listener>,
which adds the requirement that the peer be a consumer of L<Net::Object::Peer>.

Listener classes used with L<Net::Object::Peer> must be derived from
this class.
