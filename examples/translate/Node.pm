#!/usr/bin/perl

package Node;

use Moo;
use strictures 2;

with 'Net::Object::Peer';

sub _cb_A { print "recieved event A\n" }

sub _cb_B { print "recieved event B\n" }

sub _cb_detach {
    my ( $self, $event ) = @_;
    $self->unsubscribe( $event->emitter );
}
1;
