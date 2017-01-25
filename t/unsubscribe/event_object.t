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


    # unsubscribe using event object
    sub _cb_oneshot {

	my ( $self, $event ) = @_;

        $self->logit( peer => $event->emitter->name );

	$self->unsubscribe( $event );
    }
}

subtest "unsubscribe from event object " => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );
    my $n2 = Node->new( name => 'N2', logger => $logger );

    cmp_expected { $n2->subscribe( $n1, 'oneshot' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N2",
        what  => "oneshot",
    };

    cmp_expected { $n1->subscribe( $n2, 'unsubscribed' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "unsubscribed",
    };

    cmp_expected { $n1->emit( 'oneshot' ) }
      $logger,
      {
       event => 'oneshot',
       self => 'N2',
       peer => 'N1',
       },
      {
       event => 'unsubscribed',
       self => 'N1',
       peer => 'N2',
       events => [ 'oneshot' ],
       };

      is( scalar $n2->subscriptions( name => 'oneshot' ), 0, "unsubscribed from oneshot" );


};

done_testing;
