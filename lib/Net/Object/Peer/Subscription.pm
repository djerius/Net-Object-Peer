# ABSTRACT: A Net::Object::Peer Subscription
package Net::Object::Peer::Subscription;

use 5.10.0;

use Scalar::Util qw[ weaken ];
use Types::Standard qw[ ConsumerOf Str CodeRef ];

use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '0.04';


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

=method as_hashref

  $hashref = $sub->as_hashref;

Return non-code attributes as a hash

=cut

sub as_hashref {

    my $self = shift;

    my %hash = map { $_ => $self->$_ } qw[ peer name ];

    weaken $hash{peer};

    return \%hash;
}

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscription> object manages a node's
subscription to an emitter.
