#! perl

use 5.10.0;
use strict;
use warnings;

use Test::Lib;
use Test2::Bundle::Extended;

use MyTest::Common;
use MyTest::Logger;

use Net::Object::Peer;

use Moo::Role ();

{
    package Class;

    use Moo;
    with 'Net::Object::Peer';
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';
    with 'MyTest::Role::LogDemolish';
}


subtest "not emphemeral" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Class->new( name => 'N1', logger => $logger );

    cmp_expected {
        my $n2 = Class->new( name => 'N2', logger => $logger );
        $n1->subscribe( $n2, 'unsubscribed' );
    }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "unsubscribed",
      },
      {
        event   => 'DEMOLISH',
        self    => 'N2',
        package => 'Class',
      },
      {
        event  => 'unsubscribed',
        self   => 'N1',
        peer   => 'N2',
        events => ['%all%'],
      };

};

subtest "emphemeral" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Class->new( name => 'N1', logger => $logger );

    my $n2_class;

    cmp_expected {
        my $n2 = Class->new( name => 'N2', logger => $logger );
        Moo::Role->apply_roles_to_object( $n2, 'Net::Object::Peer::Ephemeral' );
	$n2_class = ref $n2;
        $n1->subscribe( $n2, 'unsubscribed' );
    }
    $logger,
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N1",
        what  => "unsubscribed",
      };

    cmp_expected {
        $n1->unsubscribe;
    }
    $logger,
      {
        event   => 'DEMOLISH',
        self    => 'N2',
        package => $n2_class,
      };


};

done_testing;

