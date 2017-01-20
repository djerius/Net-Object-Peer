# ABSTRACT: Net::Object::Peer specfic Listener
package Net::Object::Peer::Listener;

use 5.10.0;

use Types::Standard qw[ ConsumerOf InstanceOf ];
use Net::Object::Peer::RefAddr;

use Moo;
use strictures 2;
use namespace::clean;
extends 'BeamX::Peer::Listener';

our $VERSION = '0.06';

has +peer => (
    is  => 'ro',
    isa => ConsumerOf ['Net::Object::Peer'],
    weak_ref => 1,
);

=attr  addr

The reference address of the true emitter

=cut

has addr => (
    is       => 'rwp',
    isa      => InstanceOf['Net::Object::Peer::RefAddr'],
    predicate => 1,
);


=begin pod_coverage

=head4 BUILD

=head4 has_addr

=end pod_coverage

=cut

sub BUILD {

    # do this as soon as possible.  if it's lazy, peer may disappear
    # before a lazy builder can run
    $_[0]->_set_addr( Net::Object::Peer::RefAddr->new( $_[0]->peer ) )
      unless $_[0]->has_addr;
}

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::Listener> is a sub-class of L<BeamX::Peer::Listener>,
which

=over

=item *

adds the requirement that the peer be a consumer of L<Net::Object::Peer>.

=item *

adds an C<addr> attribute, which contains the refaddr of C<peer>.

=back

Listener classes used with L<Net::Object::Peer> must be derived from
this class.
