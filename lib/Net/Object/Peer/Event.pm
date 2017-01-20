# ABSTRACT: An event emitted by a Net::Object::Peer node
package Net::Object::Peer::Event;

use 5.10.0;

use Types::Standard qw[ ConsumerOf InstanceOf ];

use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '0.06';

extends 'Beam::Event';

has '+emitter' => (
    is       => 'ro',
    isa      => ConsumerOf ['Net::Object::Peer'],
    required => 1,
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

    # do this as soon as possible.  if it's lazy, emitter may disappear
    # before a lazy builder can run

    $_[0]->_set_addr( Net::Object::Peer::RefAddr->new( $_[0]->emitter ) )
      unless $_[0]->has_addr;
}

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::Event> is a sub-class of L<Beam::Event>,
which adds

=over

=item *

the requirement that the emitter be a consumer of L<Net::Object::Peer>.

=item *

a new attribute, C<addr>, which will contain the refaddr of the true
emitter object, in the case that C<emitter> is masqueraded.

=back

Event classes used with L<Net::Object::Peer> must be derived from
this class.
