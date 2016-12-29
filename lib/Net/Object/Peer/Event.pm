# ABSTRACT: An event emitted by a Net::Object::Peer node
package Net::Object::Peer::Event;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.04';

use Types::Standard 'ConsumerOf';
use namespace::clean;

use Moo;
extends 'Beam::Event';

has emitter => (
    is       => 'ro',
    isa      => ConsumerOf ['Net::Object::Peer'],
    required => 1,
);



1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::Event> is a sub-class of L<Beam::Event>,
which adds the requirement that the emitter be a consumer of L<Net::Object::Peer>.

Event classes used with L<Net::Object::Peer> must be derived from
this class.
