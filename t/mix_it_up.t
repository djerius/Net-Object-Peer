#! perl

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


    sub _cb_changed {

        my ( $self, $event ) = @_;

        $self->logit( peer => $event->emitter->name );
        $self->emit( 'changed' );

    }

    sub _cb_echo {

        my ( $self, @args ) = @_;

        $self->logit( args => \@args );
        return;
    }

    sub _cb_n1 { }
    sub _cb_n2 { }
}

subtest "mix it up" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );
    my $n2 = Node->new( name => 'N2', logger => $logger );
    my $n3 = Node->new( name => 'N3', logger => $logger );
    my $n4 = Node->new( name => 'N4', logger => $logger );

    # n1 will follow n2's changes (and re-emit the event );
    cmp_expected { $n1->subscribe( $n2, 'changed' ) }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "changed"
      };

    # n4 will also follow n2's changes (and re-emit the event );
    cmp_expected { $n4->subscribe( $n2, 'changed' ) }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N4",
        what  => "changed"
      };

    # n3 will follow n1's changes (and re-emit the event );
    cmp_expected { $n3->subscribe( $n1, 'changed' ) }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => "changed"
      };

    # n2 will notice if n1 is unsubscribed from it
    cmp_expected { $n2->subscribe( $n1, 'unsubscribe' ) }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N2",
        what  => "unsubscribe"
      };


    # this will cause a cascade of changed events
    cmp_expected { $n2->emit( 'changed' ) }
    $logger,
      {
        event => "changed",
        self  => "N1",
        peer  => "N2",
      },
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      },
      {
        event => "changed",
        self  => "N4",
        peer  => "N2",
      };

    # n2 wants to directly message n4
    cmp_expected { $n2->send( $n4, 'changed' ) }
    $logger,
      {
        event => "changed",
        self  => "N4",
        peer  => "N2",
      };

    # n1 doesn't care about n2 anymore
    cmp_expected { $n1->unsubscribe( $n2, 'changed' ) }
    $logger,
      {
        event  => "unsubscribe",
        self   => "N2",
        peer   => "N1",
        events => [ "changed", ],
      };

    # but n4 still does
    cmp_expected { $n2->emit( 'changed' ) }
    $logger,
      {
        event => "changed",
        self  => "N4",
        peer  => "N2",
      };

    # n3 still follows n1
    cmp_expected { $n1->emit( 'changed' ) }
    $logger,
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    # now it doesn't.  Since n3 didn't subscribe to unsubscribe events
    # from n1, expect no output
    cmp_expected { $n3->unsubscribe( $n1 ) }
    $logger;

    # howling in the wilderness
    cmp_expected { $n1->emit( 'changed' ) }
    $logger;


};

done_testing;
