# ABSTRACT: A Net::Object::Peer Subscription
package Net::Object::Peer::Subscription;

use 5.10.0;
use strict;
use warnings;

our $VERSION = "0.01";

use Types::Standard qw[ ConsumerOf Str CodeRef ];
use namespace::clean;

use Moo;


=attr peer

=cut

has peer => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
    isa      => ConsumerOf ['Net::Object::Peer'],
);

=attr name

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _unsubscribe => (
    is       => 'ro',
    init_arg => 'unsubscribe',
    isa      => CodeRef,
    required => 1,
);

=method unsubscribe

=cut

sub unsubscribe { $_[0]->_unsubscribe->() }

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscription> object manages a node's
subscription to an emitter.
