#!/usr/bin/perlperl

use strict;
use warnings;

use 5.10.0;

package Node {
   use Moo;
   with 'Net::Object::Peer';

   has name => is => ( 'ro', required => 1 );

   sub _notify_subscribed {

     my ( $self, $peer, $name ) = @_;

     say $self->name, ":\tpeer (@{[ $peer->name ]}) subscribed to event $name";

   }

   sub _cb_changed {

       my ( $self, $event ) = @_;

       say $self->name, ":\tpeer (@{[ $event->emitter->name ]}) changed";

   }

   sub _cb_unsubscribe {

       my ( $self, $event ) = @_;

	say $self->name, ":\tpeer (@{[ $event->emitter->name ]}) unsubscribed";
   }
}


my $n1 = Node->new( name => 'N1' );
my $n2 = Node->new( name => 'N2' );

# n1 will follow n2's changes
$n1->subscribe( $n2, 'changed' );

# n2 will notice if n1 is unsubscribed from it
$n2->subscribe( $n1, 'unsubscribe' );

$n2->emit( 'changed' );

# destroy n1; n1 will unsubscribe and n2 will be notified 
undef $n1;

