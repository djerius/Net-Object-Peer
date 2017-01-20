# ABSTRACT: A Net::Object::Peer Subscription for an ephemeral peer
package Net::Object::Peer::Subscription::Ephemeral;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.05';

use Moo;
extends 'Net::Object::Peer::Subscription';

has '+peer' => ( is => 'ro', weak_ref => 0 );

1;
# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscription::Ephemeral> object manages a
node's subscription to an ephemeral emitter.  It keeps a strong
reference to the emitter so that the emitter does not disappear after
it's defining scope is been destroyed.


