# ABSTRACT: Peer-to-Peer Publish/Subscribe Network of Objects
package Net::Object::Peer;

use 5.10.0;

use Carp;
our @CARP_NOT = qw( Beam::Emitter );

use Scalar::Util qw[ refaddr weaken ];
use Data::OptList qw[ mkopt ];
use Safe::Isa;
use Ref::Util qw[ is_arrayref ];
use Types::Standard ':all';

use Moo::Role;
use strictures 2;

use MooX::ProtectedAttributes;

our $VERSION = '0.04';

use Net::Object::Peer::Event;
use Net::Object::Peer::UnsubscribeEvent;
use Net::Object::Peer::Listener;
use Net::Object::Peer::Emitter;
use Net::Object::Peer::Subscriptions;

use Sub::QuoteX::Utils qw[ quote_subs ];

=begin pod_coverage

=head3 UnsubscribeEvent

=head3 Subscription

=head3 Listener

=head3 Emitter

=end pod_coverage

=cut

use constant UnsubscribeEvent => __PACKAGE__ . '::UnsubscribeEvent';
use constant Emitter          => __PACKAGE__ . '::Emitter';


use namespace::clean;

has _subscriptions => (
    is        => 'ro',
    init_args => undef,
    isa       => InstanceOf ['Net::Object::Peer::Subscriptions'],
    default   => sub { Net::Object::Peer::Subscriptions->new },
);

protected_has _emitter => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { Net::Object::Peer::Emitter->new },
    handles  => [qw< emit_args send_args >],
);



=method build_sub

  $coderef = $self->build_sub( $emitter, @tuple );

C<build_sub> is the method responsible for creating and
compiling the code for an event handler. It is invoked
from the L</subscribe()> method, with the following parameters

=over

=item C<$emitter>

The emitter object.

=item C<@tuple>

the tuple passed to L</subscribe> for this event.

=back

The default implementation will return a L<Sub::Quote::quote_sub|Sub::Quote/quote_sub>
generated code reference for method calls and code specified as a
string.  See L<Net::Object::Peer::Cookbook/Loop Detecton> for an
example of using this attribute to inline additional code in the event
handler.



=cut

sub build_sub {

    my ( $self, $emitter, $name, $arg ) = @_;

    return do {

        if ( !defined $arg ) {

            quote_subs( [ $self, "_cb_$name" ] );
        }

        elsif ( 'HASH' eq ref $arg ) {

            my %arg = %$arg;
            delete $arg{name};

            if ( defined $arg{method} ) {

                quote_subs( [ $self, delete $arg{method}, %arg ] );
            }

            elsif ( defined $arg->{code} ) {

                quote_subs( [ delete $arg{code}, %arg ] );
            }

	    else {

		croak( __PACKAGE__ . "::build_sub: can't figure out what to do with \%arg" );
	    }
        }

        elsif ( 'CODE' eq ref $arg ) {

            $arg;
        }

        else {

            croak( __PACKAGE__ . "::build_sub: illegal value for \$arg" );
        }
    };

}

=method subscribe

  $self->subscribe( $peer, @event_tuple [, @event_tuple, ...  ] );

Subscribe to one or more events sent by C<$peer>, which must consume
the L<Net::Object::Peer> role.

The event name and the action to be performed when the event is
emitted are specified by a tuple with the following forms:

=over

=item C<< $event_name >>

the event handler will invoke the C<_cb_${event_name}> method on C<$self>.

=item C<< $event_name => { method => $method_name } >>

The event handler will invoke the C<$method_name> method on C<$self>.

=item C<< $event_name => CODEREF >>

The passed code reference is called.

=item C<< $event_name => { code => $code, capture => \%capture } >>

C<$code> is a string containing code to be run by the event handler.
C<%capture> is a hash containing variable captures. See the
documentation for "\%captures" in L<Sub::Quote/quote_sub> for more
information.

=back

If C<$peer> provides a C<_notify_subscribed> method, that will be invoked as

  $peer->_notify_subscribed( $self, $event_name, ... );

for each subscription.

=cut

sub subscribe {

    my $self = shift;
    my $peer = shift;

    my $subscriptions = $self->_subscriptions;

    weaken $self;
    weaken $peer;

    my $notify_subscribed = $peer->can( '_notify_subscribed' );

    my $args = Data::OptList::mkopt(
        \@_,
        {
            moniker        => 'events',
            require_unique => 1,
            must_be        => [ 'CODE', 'SCALAR', 'HASH' ],
        } );

    # don't register anything until we've parsed the input list of
    # event names and possible subs in order to make this as atomic as
    # possible.
    my @register;
    for my $opt ( @$args ) {

        my ( $name, $arg ) = @$opt;

        croak( "\$name must be a string\n" )
          if ref $name;
        push @register, [ $name, $self->build_sub( $peer, $name, $arg ) ];
    }

    for my $event ( @register ) {


        my ( $name, $sub ) = @$event;

        $self->_subscriptions->remove(
            name => $name,
            peer => $peer,
        );

        $self->_subscriptions->add(
                name => $name,
                peer => $peer,
                unsubscribe =>
                  $peer->_emitter->subscribe( $name, $sub, peer => $self ),
            );

    }

    $peer->$notify_subscribed( $self, map { $_->[0] } @register )
      if $notify_subscribed;

}


=method unsubscribe

  # Unsubscribe from all events from all peers.
  $self->unsubscribe;

  # Unsubscribe from all events emitted by a peer
  $self->unsubscribe( $peer );

  # Unsubscribe from one or more events emitted by a peer
  $self->unsubscribe( $peer, $event_name [, $event_name [, ... ]);

  # Unsubscribe from one or more events emitted by all peers
  $self->unsubscribe( $event_name [, $event_name [, ... ] ] )

Unsubscribe from events/peers. After unsubscription, an I<unsubscribe>
event with a L<Net::Object::Peer::UnsubscribeEvent> as a payload will
be sent to affected peers who have subscribed to the unsubscribed event(s).

=cut

sub unsubscribe {

    my $self = shift;

    return $self->_unsubscribe_all
      unless @_;

    if ( $_[0]->$_does( __PACKAGE__ ) ) {

        # $peer, $name, ...
        return $self->_unsubscribe_from_peer_events( @_ )
          if @_ > 1;

        # $peer
        return $self->_unsubscribe_from_peer( @_ );
    }

    # $name, ...
    return $self->_unsubscribe_from_events( @_ );

}

sub _unsubscribe_all {

    my $self = shift;

    # say $self->name, ":\tunsubscribing from all peers";

    $self->_subscriptions->remove;

    # signal peers that unsubscribe has happened.

    # say $self->name, ":\tnotifying all subscribed peers of unsubscription";

    $self->emit( 'unsubscribe', class => UnsubscribeEvent );

    return;
}

sub _unsubscribe_from_peer_events {

    my ( $self, $peer ) = ( shift, shift );

    my @unsubscribed;

    for my $name ( @_ ) {

        for my $subscription (
            $self->_subscriptions->remove(
                peer => $peer,
                name => $name,
            ) )
        {
            # say $self->name, ":\tunsubscribing from ", $peer->name, ":$name";

            push @unsubscribed, $name;
        }
    }

    if ( @unsubscribed ) {

        # say $self->name, ":\tnotifying ", $peer->name,
        #   " of unsubscription from ", join( ', ', @unsubscribed );

        $self->send(
            $peer, 'unsubscribe',
            class       => UnsubscribeEvent,
            event_names => \@unsubscribed,
        );
    }

    return;
}


sub _unsubscribe_from_peer {

    my ( $self, $peer ) = @_;

    # say $self->name, ":\tunsubscribing from ", $peer->name;

    $self->_subscriptions->remove( peer => $peer );

    # say $self->name, ":\tnotifying ", $peer->name,
    #   " of unsubscription from all events";

    $self->send( $peer, 'unsubscribe', class => UnsubscribeEvent );

    return;
}

sub _unsubscribe_from_events {

    my ( $self, @names ) = @_;

    return unless @names;

    my %subs;
    my @subs = $self->_subscriptions->remove(
        sub {
            grep { $_[0]->name eq $_ } @names;
        } );

    for my $sub ( @subs ) {

        my $list = $subs{ refaddr $sub->{peer} } ||= [ $sub->{peer} ];
        push @$list, $sub->{name};
    }

    for my $sub ( values %subs ) {

        my ( $peer, @names ) = @_;
        $self->emit(
            'unsubscribe',
            class       => UnsubscribeEvent,
            event_names => \@names,
        );
    }


    return;
}

=method detach

  $self->detach;

Detach the object from the network.  It will

=over

=item 1

Unsubscribe from all events from all peers.

=item 2

Emit an C<unsubscribe> event with a L<Net::Object::Peer::UnsubscribeEvent> as a payload.

=item 3

Emit a C<detach> event.

=back

=cut

sub detach {
    my $self = shift;

    $self->unsubscribe;
    $self->emit( 'detach' );
}


=method subscriptions

  # return all subscriptions
  my @subscriptions = $self->subscriptions;

  # return matching subscriptions
  my @subscriptions = $self->subscriptions( $coderef | %spec );

Returns the events to which C<$self> is subscribed as a list of
hashrefs (see L<Net::Object::Peer::Subscription::as_hashref>).  If
arguments are specified, only those which match are returned; see
L<Net::Object::Peer::Subscrition/find>;


=cut

sub subscriptions {

    my $self = shift;

    return @_ ? $self->_subscriptions->find( @_ ) : $self->_subscriptions->list;
}

=method emit

  $self->emit( $event_name, %args );

Broadcast the named event to all subscribed peers.  C<%args> contains
arguments to be passed the the payload class constructor.  The default
payload class is a L<Net::Object::Peer::Event> object; use the C<class> key to
specify an alternate class, which must be erived from B<Net::Object::Peer::Event>.

=cut

sub emit {

    my ( $self, $name ) = ( shift, shift );

    $self->_emitter->emit(
        $name,
        class   => 'Net::Object::Peer::Event',
        emitter => $self,
        @_
    );
}

=method send

  $self->send( $peer, $event_name, %args );

This is similar to the L</emit> method, but only sends the event to the
specified peer.

=cut

sub send {

    my ( $self, $peer, $name ) = ( shift, shift, shift );

    $self->_emitter->send(
        $peer,
        $name,
        class   => 'Net::Object::Peer::Event',
        emitter => $self,
        @_
    );
}


=method emit_args

  $self->emit_args( $event_name, @args );

Broadcast the named event to all subscribed peers. C<@args> will be
passed directly to each subscriber's callback.

=cut

=method send_args

  $self->send_args( $peer, $event_name, @args );

This is similar to the L</emit_args> method, but only sends the event to the
specified peer.

=cut

# allow emit_args( unsubscribe => $event_name );
# or emit( unsubscribe ) which will unsubscribe all events from the emitter
sub __cb_unsubscribe {

    if ( $_[1]->$_isa( 'Beam::Event' ) ) {
        splice( @_, 1, 1, $_[1]->emitter );
    }
    goto &unsubscribe;
}

=begin pod_coverage

=head3 DEMOLISH

=end pod_coverage

=cut

sub DEMOLISH {}

around DEMOLISH => sub {

    my $orig = shift;

    my ( $self, $in_global_destruction ) = @_;

    $self->detach
      unless $in_global_destruction;

    &$orig;
};


1;

# COPYRIGHT

__END__

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis.pl

Resulting in:

# COMMAND: perl -Ilib examples/synopsis.pl

=head1 DESCRIPTION

B<Net::Object::Peer> is a L<Moo> L<< Role|Moo::Role >> which
implements a publish/subscribe peer-to-peer messaging system, based
upon L<Beam::Emitter>.  Objects in the network may broadcast events
to all subscribers or may send events to a particular subscriber.

Subscriptions and unsubscriptions are tracked and messages will be
sent to affected objects upon request.

While B<Net::Object::Peer> is designed around the concept of nodes
being objects with methods as event handlers, it retains
L<Beam::Emitter>'s ability to register code references as well.

L<Net::Object::Peer::Cookbook> provides some recipes.


=head2 Usage

As B<Net::Object::Peer> is purely peer based with no common message
bus, a network is built up by creating a set of network nodes and
linking them via subscriptions.

  my $n1 = Node->new( name => 'N1' );
  my $n2 = Node->new( name => 'N2' );

  $n1->subscribe( $n2, 'changed' );

Here C<$n1> I<subscribes to> C<$n2>'s C<changed> event. By default,
C<$n1>'s C<_cb_changed> method is invoked when C<$n2> emits a
C<changed> event.

=head2 Events

When a subscriber recieves an event, its registered handler for that
event type is invoked.  If the object creating the event used the
L</emit> or L</send> methods,

  $emitter->emit( $event_name );

the event handler will be invoked as

  $subscriber->method( $event );

where C<$event> is an object derived from the L<Net::Object::Peer::Event> class.
(This assumes that the handler is a method; it may be a simple callback).

If the event was created with the L</emit_args> or L</send_args> methods,

  $emitter->emit_args( $event_name, @arguments );

the event handler will invoked as

  $subscriber->method( @arguments );


=head3 Subscription and Unsubscription Events

When a subscriber registers one or more event handlers with an emitter
via the subscriber's L</subscribe> method, the emitter's
C<_notify_subscribed> method will be invoked (if it exists) as

  $emitter->_notify_subscribed( $subscriber, @event_names );

If the subscription already exists, it will be unsubscribed and
then resubscribed.

After a subscriber de-registers a handler, either explicitly via
L</unsubscribe> or when the object is destroyed, it will L</emit> an
C<unsubscribe> event with a L<Net::Object::Peer::UnsubscribeEvent>
object as a payload.

While emitters are not automatically subscribed to C<"unsubscribe">
events, this is easily accomplished by adding code to the emitters'
C<_notify_subscribed> method.

=head3 Detach Events

When an object is destroyed, it emits a C<detach> event after
unsubscribing from other peers' events.  This 
