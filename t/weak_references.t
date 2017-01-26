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

    sub default_events { qw[ changed ] }

    sub _cb_changed {

        my ( $self, $event ) = @_;

        $self->logit( peer => $event->emitter->name );
        $self->emit( 'changed' );

    }
}

subtest "weak references" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );

    cmp_expected {
        my $n2 = Node->new( name => 'N2', logger => $logger );
        $n1->subscribe( $n2, 'unsubscribed' );
        $n2->subscribe( $n1, 'changed' );
        undef $n2;
    }
    $logger,
    {
        event => 'notify_subscribed',
        self  => 'N2',
        peer  => 'N1',
        what  => 'unsubscribed',
    },
      {
        event => 'notify_subscribed',
        self  => 'N1',
        peer  => 'N2',
        what  => 'changed',
      },
      {
        event  => 'unsubscribed',
        events => ['%all%'],
        self   => 'N1',
        peer   => 'N2',
      };

};

done_testing;
