# ABSTRACT: Peer-to-Peer Publish/Subscribe Network of Objects
package Net::Object::Peer;

use 5.10.0;
use strictures 2;

use Carp;
our @CARP_NOT = qw( Beam::Emitter );

use List::Util qw[ all first uniqstr ];
use Scalar::Util qw[ refaddr weaken ];
use Data::OptList qw[ mkopt ];
use Safe::Isa;
use Ref::Util qw[ is_arrayref ];
use Types::Standard ':all';
use Sub::Quote;

use Moo::Role;

use MooX::ProtectedAttributes;

our $VERSION = '0.06';

use Net::Object::Peer::Event;
use Net::Object::Peer::Types qw[ -all ];
use Net::Object::Peer::UnsubscribeEvent;
use Net::Object::Peer::Listener;
use Net::Object::Peer::Emitter;
use Net::Object::Peer::RefAddr;
use Net::Object::Peer::Subscriptions;

use Sub::QuoteX::Utils qw[ quote_subs ];

=begin pod_coverage

=head3 UnsubscribeEvent

=head3 Subscription

=head3 Listener

=head3 Emitter

=end pod_coverage

=cut

use constant UNSUBSCRIBED     => 'unsubscribed';
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

=attr event_handler_prefix

The string which prefixes default event handler method names. See
L</subscribe>.  It will by default be initialized to the return value
of the L</default_event_handler_prefix> method.  It may be specified
during object construction.

For example, the default handler method name for an event named
C<changed> would be C<_cb_changed>.  The class must provide that
method. See L</subscribe> for more information.

=cut

has event_handler_prefix => (
    is      => 'lazy',
    isa     => Str,
    builder => sub { $_[0]->default_event_handler_prefix } );



has _events_arr => (
    is      => 'rwp',
    isa     => ArrayRef [Identifier],
    coerce  => qsub q{ 'ARRAY' eq ref $_[0] ? [ @{$_[0]} ] : [ $_[0] ]; },
    default => qsub q{ ['detach', 'unsubscribed', $_[0]->default_events ]; },
    init_arg => 'events',
    trigger => 1
);

has _events_hash => (
    is        => 'lazy',
    init_args => undef,
    clearer   => 1,
);

sub _trigger__events_arr {

    my $self = shift;

    # force rebuild of _events attribute
    $self->_clear_events_hash;

    # _events gives us a unique list which includes the standard ones.
    # we know that we own the arrayref in $self->events because of the
    # its coercion.
    @{ $self->_events_arr } = keys %{ $self->_events_hash };
}

sub _build__events_hash {

    my %events = ( detach => 1, unsubscribed => 1 );

    my $events_arr = $_[0]->_events_arr;

    # just need to populate the keys
    @events{ @{ $events_arr } } = undef
      if $events_arr;

    \%events;
}

=method  emits_events

   $bool = $obj->emits_events( @event_names );

Returns true if the object emits I<all> of the named events

=cut

sub emits_events {

    my $self = shift;
    my $events = $self->_events_hash;

    return all { exists $events->{$_} } @_;
}

=method  default_events

  @events = $class->default_events;

Returns a list of events which this class will emit, excluding the C<detach> and C<unsubscribed> events.
The default implementation returns an empty list.  A per object event list may be specified via
the L</events> attribute or the C<events> option to the L<constructor|/new>.

=cut

sub default_events { }



=attr addr

A L<Net::Object::Peer::RefAddr> object providing a unique identity for this emitter.

=cut

has addr => (
    is        => 'rwp',
    isa       => InstanceOf ['Net::Object::Peer::RefAddr'],
    init_arg  => undef,
    predicate => 1,
);

=begin pod_coverage

=head4 has_addr

=head4 BUILD

=end pod_coverage

=cut

sub BUILD { }

before BUILD => sub {

    my $self = shift;
    $self->_set_addr( Net::Object::Peer::RefAddr->new( $self ) );

};


=method new

  $obj = Net::Object::Peer->new( %args | \%args );

Construct a new object.  The following arguments are available:

=over

=item event_handler_prefix => I<string>

The string which prefixes default event handler method names. See L</event_handler_prefix>

=item events => I<string> | I<arrayref>

The name(s) of the event(s) this object will emit (don't include the
C<unsubscribed> and C<detach> events).  May be a single string or an
arrayref. If not specified, the list of events will be initialized via the
L</default_events> class method.

=back

=cut

=method default_event_handler_prefix

This class method returns the prefix for the default event handler method names.
It defaults to returning C<_cb_>.

=cut

sub default_event_handler_prefix { '_cb_' }

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

            quote_subs( [ $self, $self->event_handler_prefix . $name ] );
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

                croak( __PACKAGE__
                      . "::build_sub: can't figure out what to do with \%arg" );
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
the L<Net::Object::Peer> role.  If C<$peer> additionally consumes the
L<Net::Object::Peer::Ephemeral> role, a strong reference to C<$peer>
is stored. (See  L<Net::Object::Peer::Cookbook/Translation/Proxy Nodes>.)

The event name and the action to be performed when the event is
emitted are specified by a tuple with the following forms:

=over

=item C<< $event_name >>

the event handler will invoke the C<${prefix}${event_name}> method on C<$self>,
where C<$prefix> is the L<event_handler_prefix attribute|/event_handler_prefix>.

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
            addr => Net::Object::Peer::RefAddr->new( $peer ),
            unsubscribe =>
              $peer->_emitter->subscribe( $name, $sub, peer => $self, ),
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

  # Unsubscribe from the peer and event specified by the passed
  # Net::Object::Peer::Event object
  $self->unsubscribe( $event_object );

  # Unsubscribe from one or more events emitted by all peers
  $self->unsubscribe( $event_name [, $event_name [, ... ] ] )

Unsubscribe from events/peers. After unsubscription, an I<unsubscribed>
event with a L<Net::Object::Peer::UnsubscribeEvent> as a payload will
be sent to affected peers who have subscribed to the unsubscribed event(s).

C<$peer> may be either a L<Net::Object::Peer> or a
L<Net::Object::Peer::RefAddr> object.

Note that B<Net::Object::Peer::Event> objects which are passed to
event handlers may have a masqueraded C<emitter> attribute.  Attempting
to unsubscribe from that C<emitter> is unwise.  Instead, pass either
the event object or the C<addr> field in that object, which is guaranteed
to identify the actual emitter subscribed to.

=cut

sub unsubscribe {

    my $self = shift;

    return $self->_unsubscribe_all
      unless @_;

    if (   $_[0]->$_does( __PACKAGE__ )
        || $_[0]->$_isa( 'Net::Object::Peer::RefAddr' ) )
    {

        # $peer, $name, ...
        return $self->_unsubscribe_from_peer_events( @_ )
          if @_ > 1;

        # $peer
        return $self->_unsubscribe_from_peer( @_ );
    }
    elsif ( $_[0]->$_isa( 'Net::Object::Peer::Event' ) ) {

        $self->_unsubscribe_from_peer_events( $_[0]->addr, $_[0]->name );

    }

    # $name, ...
    return $self->_unsubscribe_from_events( @_ );

}

sub _unsubscribe_all {

    my $self = shift;

    $self->_subscriptions->remove
      if defined $self->_subscriptions;

    # signal peers that unsubscribe has happened.
    $self->emit( UNSUBSCRIBED, class => UnsubscribeEvent );

    return;
}

sub _find_peer_spec {

    my $peer = shift;

    return (
          $peer->$_does( __PACKAGE__ )               ? ( peer => $peer )
        : $peer->isa( 'Net::Object::Peer::RefAddr' ) ? ( addr => $peer )
        :   croak( "can't grok \$peer: $peer\n" ),
    );

}

sub _unsubscribe_from_peer_events {

    my ( $self, $peer ) = ( shift, shift );

    my %spec = _find_peer_spec( $peer );

    my @unsubs = map {
        my $name = $_;
        map +{ name => $name, subs => $_ },
          $self->_subscriptions->remove( %spec, name => $name )
    } @_;

    # if passed a refaddr, extract peer object from deleted subscriptions
    if ( defined $spec{addr} ) {

        # check for subs where peer is still alive
        my $sub = first { defined $_->{peer} } map { $_->{subs} } @unsubs;

        return unless defined $sub;

        $peer = $sub->{peer};
    }

    if ( @unsubs ) {

        $self->send(
            $peer, UNSUBSCRIBED,
            class       => UnsubscribeEvent,
            event_names => [ uniqstr map { $_->{name} } @unsubs ] );
    }

    return;
}


sub _unsubscribe_from_peer {

    my ( $self, $peer ) = @_;

    # say $self->name, ":\tunsubscribing from ", $peer->name;

    my %spec = _find_peer_spec( $peer );

    my @unsubs = $self->_subscriptions->remove( %spec );

    # if passed a refaddr, extract peer object from deleted subscriptions
    if ( defined $spec{addr} ) {

        # check for subs where peer is still alive
        my $sub = first { defined $_->{peer} } @unsubs;

        return unless defined $sub;

        $peer = $sub->{peer};
    }

    $self->send( $peer, UNSUBSCRIBED, class => UnsubscribeEvent );

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

    for my $sub ( grep { defined $_->{peer} } @subs ) {

        my $list = $subs{ 0 + $sub->{addr} } ||= [ $sub->{peer} ];
        push @$list, $sub->{name};
    }

    for my $sub ( values %subs ) {

        my ( $peer, @event_names ) = @$sub;

        $self->send(
            $peer,
            UNSUBSCRIBED,
            class       => UnsubscribeEvent,
            event_names => \@event_names,
        );
    }


    return;
}

=method events

  @events = $obj->events;
  $obj->events( \@event_names | $event_name );

As a getter, returns a list of event names which the object may emit.

As a setter, accepts either an arrayref or a single event name.  Event
names must a valid Perl identifier (e.g., no C<:> or C<-> characters).

=cut

sub events {

    my $self = shift;

    if ( @_ ) {

	$self->_set__events_arr( @_ );
	return;
    }

    return @{ $self->_events_arr };

}

=method detach

  $self->detach;

Detach the object from the network.  It will

=over

=item 1

Unsubscribe from all events from all peers.

=item 2

Emit an C<unsubscribed> event with a L<Net::Object::Peer::UnsubscribeEvent> as a payload.

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
specify an alternate class, which must be derived from B<Net::Object::Peer::Event>.

=cut

sub emit {

    my ( $self, $name ) = ( shift, shift );

    $self->_emitter->emit(
        $name,
        class   => 'Net::Object::Peer::Event',
        emitter => $self,
        @_,
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
        @_,
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

=begin pod_coverage

=head3 DEMOLISH

=end pod_coverage

=cut

sub DEMOLISH { }

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
C<unsubscribed> event with a L<Net::Object::Peer::UnsubscribeEvent>
object as a payload.

While emitters are not automatically subscribed to C<unsubscribed>
events, this is easily accomplished by adding code to the emitters'
C<_notify_subscribed> method.

=head3 Detach Events

When an object is destroyed, it emits a C<detach> event after
unsubscribing from other peers' events.
