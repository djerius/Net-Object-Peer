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
    package Node1;

    use Types::Standard 'InstanceOf';
    use Carp;

    use Moo;
    with 'Net::Object::Peer';
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';

    sub _cb_detach {
        my ( $self, $event ) = @_;
	$self->logit( peer => $event->emitter->name );
    }

    *_mypfx_detach = \&_cb_detach;


    around '_cb_detach' => sub {

    	croak "found wrong routine\n";
    };
}


{
    package Node2;
    use Moo;
    extends 'Node1';

    sub default_event_handler_prefix { '_mypfx_' };
}

subtest "default prefix" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node1->new( name => 'N1', logger => $logger );
    my $n2 = Node1->new( name => 'N2', logger => $logger );


    cmp_expected {
        $n2->subscribe( $n1, 'detach' );
    }
    $logger,
      {
        event => 'notify_subscribed',
        self  => 'N1',
        peer  => 'N2',
        what  => 'detach',
      };

   like( dies { $n1->detach }, qr/found wrong routine/, "correctly failed" );

};

subtest "prefix via constructor" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node1->new( name => 'N1', logger => $logger, event_handler_prefix => '_mypfx_' );
    my $n2 = Node1->new( name => 'N2', logger => $logger, event_handler_prefix => '_mypfx_' );


    cmp_expected {
        $n2->subscribe( $n1, 'detach' );
    }
    $logger,
      {
        event => 'notify_subscribed',
        self  => 'N1',
        peer  => 'N2',
        what  => 'detach',
      };

   ok( lives { $n1->detach }, "correctly did not fail" );

};

subtest "prefix via method" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node2->new( name => 'N1', logger => $logger );
    my $n2 = Node2->new( name => 'N2', logger => $logger );


    cmp_expected {
        $n2->subscribe( $n1, 'detach' );
    }
    $logger,
      {
        event => 'notify_subscribed',
        self  => 'N1',
        peer  => 'N2',
        what  => 'detach',
      };

   ok( lives { $n1->detach }, "correctly did not fail" );

};

done_testing;
