#!/usr/bin/perlperl

use strict;
use warnings;

use 5.10.0;

package Node;
use Moo;
with 'Net::Object::Peer';

has name => is => ( 'ro', required => 1 );

sub _notify_subscribed {
    my ( $self, $peer, $name ) = @_;
    say $self->name, ":\t@{[ $peer->name ]} subscribed to event $name";
}

sub _cb_hey {
    my ( $self, $event ) = @_;
    say $self->name,
      ":\t@{[ $event->emitter->name ]} sent @{[$event->name]}";
}

sub _cb_unsubscribe {
    my ( $self, $event ) = @_;
    say $self->name, ":\t@{[ $event->emitter->name ]} unsubscribed";
}

package main;


my $n1 = Node->new( name => 'N1' );
my $n2 = Node->new( name => 'N2' );
my $n3 = Node->new( name => 'N3' );

# Net::Object::Peer provides an "unsubscribe" event; $n1 will be
# notified when $n2 unsubscribes from it
$n1->subscribe( $n2, 'unsubscribe' );

# $n2 and $n3 will be notified when $n1 sends a "hey" event, and $n1
# will be notified that they have subscribed 

$n2->subscribe( $n1, 'hey' );
$n3->subscribe( $n1, 'hey' );

# both $n2 and $n3 will get notified
$n1->emit( 'hey' );

# only $n2 gets notified
$n1->send( $n2, 'hey' );

# destroy $n2; $n2 will unsubscribe from all of its events and $n1
# will be notified that $n2 has unsubscribed from it.
undef $n2;

