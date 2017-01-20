use 5.10.0;
use strict;
use warnings;

use Test::Lib;
use Test2::Bundle::Extended;
use MyTest::Common;
use MyTest::Logger;

use Net::Object::Peer;

{
    package Node;

    use Types::Standard 'InstanceOf';

    use Moo;
    with 'Net::Object::Peer';
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';


    # unsubscribe one event using refaddr
    sub _cb_oneshot_event {

	my ( $self, $event ) = @_;

        $self->logit( peer => $event->emitter->name );

	$self->unsubscribe( $event->addr, $event->name );
    }

    # unsubscribe all events using refaddr
    sub _cb_oneshot_event_all {

	my ( $self, $event ) = @_;

        $self->logit( peer => $event->emitter->name );

	$self->unsubscribe( $event->addr );
    }


}

subtest "unsubscribe from peer, one event" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );
    my $n2 = Node->new( name => 'N2', logger => $logger );

    cmp_expected { $n2->subscribe( $n1, 'oneshot_event' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N2",
        what  => "oneshot_event",
    };

    cmp_expected { $n1->subscribe( $n2, 'unsubscribe' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "unsubscribe",
    };

    cmp_expected { $n1->emit( 'oneshot_event' ) }
      $logger,
      {
       event => 'oneshot_event',
       self => 'N2',
       peer => 'N1',
       },
      {
       event => 'unsubscribe',
       self => 'N1',
       peer => 'N2',
       events => [ 'oneshot_event' ],
       };

      is( scalar $n2->subscriptions( name => 'oneshot' ), 0, "unsubscribed from oneshot_event" );


};

subtest "unsubscribe from peer, all events" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );
    my $n2 = Node->new( name => 'N2', logger => $logger );

    cmp_expected { $n2->subscribe( $n1, 'oneshot_event', 'oneshot_event_all' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N2",
        what  => [ "oneshot_event", "oneshot_event_all" ],
    };

    cmp_expected { $n1->subscribe( $n2, 'unsubscribe' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "unsubscribe",
    };

    cmp_expected { $n1->emit( 'oneshot_event_all' ) }
      $logger,
      {
       event => 'oneshot_event_all',
       self => 'N2',
       peer => 'N1',
       },
      {
       event => 'unsubscribe',
       self => 'N1',
       peer => 'N2',
       events => [ '%all%' ],
       };

      is( scalar $n2->subscriptions( name => 'oneshot' ), 0, "unsubscribed from oneshot_event_all" );


};
done_testing;
