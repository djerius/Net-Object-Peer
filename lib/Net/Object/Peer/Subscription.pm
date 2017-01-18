# ABSTRACT: A Net::Object::Peer Subscription
package Net::Object::Peer::Subscription;

use 5.10.0;

use Scalar::Util qw[ weaken refaddr ];
use Types::Standard qw[ ConsumerOf Str CodeRef ];

use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '0.04';


=attr peer

A weak reference to the peer object subscribed to.

=cut

has peer => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
    isa      => ConsumerOf ['Net::Object::Peer'],
);

=attr addr

The address returned by L<Scalar::Util::refaddr|Scalar::Util/refaddr> for
the L</peer> attribute.

=cut

has addr => (
    is       => 'rwp',
    init_arg => undef,
);

=attr name

The name of the event listened for.

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


=begin pod_coverage

=head3 BUILD

=end pod_coverage

=cut

sub BUILD {

    my $self = shift;

    $self->_set_addr( refaddr $self->peer );
}

=method unsubscribe

=cut

sub unsubscribe { $_[0]->_unsubscribe->() }

=method as_hashref

  $hashref = $sub->as_hashref;

Return non-code attributes as a hash

=cut

sub as_hashref {

    my $self = shift;

    my %hash = map { $_ => $self->$_ } qw[ peer name addr ];

    weaken $hash{peer};

    return \%hash;
}

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscription> object manages a node's
subscription to an emitter.
