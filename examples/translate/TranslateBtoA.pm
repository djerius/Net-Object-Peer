#!/usr/bin/perl

use strict;
use warnings;

package TranslateBtoA;
use Types::Standard ':all';
use Moo;
with 'Net::Object::Peer';

has proxy_for => (
    is       => 'ro',
    weak_ref => 1,    # very important!
    required => 1,
    isa      => ConsumerOf ['Net::Object::Peer'],
);

sub BUILD {
    $_[0]->subscribe( $_[0]->proxy_for, 'B', 'detach' );
}

sub _cb_B {
    my ( $self, $event ) = @_;

    # re-emit as A
    $self->emit( 'A', emitter => $event->emitter );
}

sub _cb_detach {

    $_[0]->emit( 'detach' );
}

1;
