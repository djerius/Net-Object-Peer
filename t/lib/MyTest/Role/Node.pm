package MyTest::Role::Node;

use Moo::Role;

requires 'logger';

has name => ( is => 'ro', required => 1 );


sub _event {
    my $up = shift || 2;
    my $caller = ( caller( $up ) )[3];
    $caller =~ s/.*::_(cb_|)//;
    return $caller;
}

sub logit {

    my $self = shift;

    $self->logger->log( {
        event => _event(),
        self  => $self->name,
        @_
    } );
}

    sub _notify_subscribed {

        my ( $self, $peer, @names ) = @_;

        $self->logit(
            peer => $peer->name,
            what => ( @names > 1 ? \@names : $names[0] ),
        );

    }

    sub _cb_unsubscribe {

        my ( $self, $event ) = @_;

        if ( $event->isa( 'Net::Object::Peer::UnsubscribeEvent' ) ) {

            $self->logit(
                peer   => $event->emitter->name,
                events => $event->event_names,
            );
        }

        else {

            $self->logit( peer => $event->emitter->name );

        }

    }

1;
