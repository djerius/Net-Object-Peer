# ABSTRACT: A collection of Net::Object::Peer::Subscriptions
package Net::Object::Peer::Subscriptions;

use 5.10.0;

use Types::Standard qw[ ArrayRef InstanceOf ];
use Ref::Util qw[ is_coderef ];
use List::Util qw[ all ];
use Safe::Isa;

use Net::Object::Peer::Subscription;
use Net::Object::Peer::Subscription::Ephemeral;


use Moo;
use strictures 2;
use namespace::clean;

our $VERSION = '0.07';

has _subscriptions => (
    is       => 'ro',
    init_arg => undef,
    isa      => ArrayRef [ InstanceOf ['Net::Object::Peer::Subscription'] ],
    default => sub { [] },
    lazy    => 1,
);

=method list

  @subs = $subs->list;

Returns a list of hashrefs containing attributes for all subscriptions.


=cut

sub list {
    return map { $_->as_hashref } @{ $_[0]->_subscriptions };
}

=method nelem

  $nelem = $subs->nelem;

return the number of elements in the list of subscriptions.

=cut

sub nelem {
    return scalar @{ $_[0]->_subscriptions };
}

=method add

  $subs->add( %attr );

Add a subscription.  See L<Net::Object::Peer::Subscription> for the
supported attributes.

=cut

sub add {
    my $self = shift;

    my %attr = ( @_ == 1 ? %{ $_[0] } : @_ );

    my $class = 'Net::Object::Peer::Subscription';
    $class .= '::Ephemeral' if $attr{peer}->$_does( 'Net::Object::Peer::Ephemeral' );

    push @{ $self->_subscriptions }, $class->new( %attr );

    return;
}

sub _find_index {

    my $self = shift;
    my $subs = $self->_subscriptions;

    if ( is_coderef( $_[0] ) ) {

        my $match = shift;
        return grep { $match->( $subs->[$_] ) } 0 .. @$subs - 1;

    }
    else {
        my %match = @_;

        return grep {
            my $sub = $subs->[$_];
            all {
                if ( $sub->can( $_ ) ) {
                    my $val = $sub->$_;

                        !defined $val && !defined $match{$_} ? 1
                      : !defined $val || !defined $match{$_} ? 0
                      :   $val eq $match{$_};
                }
                else {
                    0;
                }
            }
            keys %match;
        } 0 .. @$subs - 1;
    }
}

=method find

  my @subs = $subs->find( $coderef | %spec );

Returns a list of hashrefs containing attributes for subscriptions
which match the passed arguments.

A single argument must be a coderef; it will be invoked with a
L<Net::Peer::Subscription> object as an argument.  It should return
true if it matches, false otherwise.

If a hash is passed, its values are compared to the attributes of
subscriptions in the list.

=cut

sub find {

    my $self = shift;

    my $subs = $self->_subscriptions;

    return unless @_;

    my @indices = $self->_find_index( @_ );
    return map { $_->as_hashref } @{$subs}[@indices];
}


=method remove

  @hashrefs = $subs->remove( $coderef | %spec );

Unsubscribe the matching subscriptions, remove them from the list of
subscriptions, and return hashrefs containing the subscriptions' event
names and peers.


=cut

sub remove {

    my $self = shift;

    my $subs = $self->_subscriptions;

    my @subs;

    if ( @_ ) {
        # need to remove subscriptions from the back to front,
        # or indices get messed up
        my @indices = reverse sort $self->_find_index( @_ );

        @subs = reverse map { splice( @$subs, $_, 1 ) } @indices;
    }

    else {
        @subs  = @$subs;
        @$subs = ();
    }

    $_->unsubscribe foreach @subs;

    return map { $_->as_hashref } @subs;
}

1;
# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscriptions> object manages a collection
of L<Net::Object::Peer::Subscriptions> objects.
