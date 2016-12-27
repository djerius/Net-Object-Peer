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
    package ClassWithDemolish;

    use Moo;
    with 'Net::Object::Peer';
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';

    sub DEMOLISH { $_[0]->logit( package => __PACKAGE__ ) }
}

{
    package ClassWithoutDemolish;

    use Moo;
    with 'Net::Object::Peer';
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';
}


subtest "no inheritance" => sub {

    subtest 'class with DEMOLISH' => sub {

        my $logger = MyTest::Logger->new;

        my $n1 = ClassWithDemolish->new( name => 'N1', logger => $logger );
        my $n2 = ClassWithDemolish->new( name => 'N2', logger => $logger );

        cmp_expected {
            $n1->subscribe( $n2, 'unsubscribe' );
        }
        $logger,
          {
            event => "notify_subscribed",
            self  => "N2",
            peer  => "N1",
            what  => "unsubscribe",
          };

        cmp_expected {
            undef $n2;
        }
        $logger,
          {
            event  => 'unsubscribe',
            self   => 'N1',
            peer   => 'N2',
            events => ['%all%'],
          },
          {
            event   => 'ClassWithDemolish::DEMOLISH',
            package => 'ClassWithDemolish',
            self    => 'N2',
          };

    };

    subtest "class without DEMOLISH" => sub {

        my $logger = MyTest::Logger->new;

        my $n1 = ClassWithoutDemolish->new( name => 'N1', logger => $logger );
        my $n2 = ClassWithoutDemolish->new( name => 'N2', logger => $logger );

        cmp_expected {
            $n1->subscribe( $n2, 'unsubscribe' );
        }
        $logger,
          {
            event => "notify_subscribed",
            self  => "N2",
            peer  => "N1",
            what  => "unsubscribe",
          };

        cmp_expected {
            undef $n2;
        }
        $logger,
          {
            event  => 'unsubscribe',
            self   => 'N1',
            peer   => 'N2',
            events => ['%all%'],
          };

    };

};

{
    package ParentWithDemolish;

    use Moo;
    with 'Net::Object::Peer';

    sub DEMOLISH { $_[0]->logit( package => __PACKAGE__ ) }
    with 'MyTest::Role::Log';
    with 'MyTest::Role::Node';
}


{
    package ChildWithDemolish;

    use Moo;
    extends 'ParentWithDemolish';

    sub DEMOLISH { $_[0]->logit( package => __PACKAGE__ ) }
}

{
    package ChildWithoutDemolish;

    use Moo;
    extends 'ParentWithDemolish';
}

subtest "inheritance" => sub {

    subtest 'class with DEMOLISH' => sub {

        my $logger = MyTest::Logger->new;

        my $n1 = ChildWithDemolish->new( name => 'N1', logger => $logger );
        my $n2 = ChildWithDemolish->new( name => 'N2', logger => $logger );

        cmp_expected {
            $n1->subscribe( $n2, 'unsubscribe' );
        }
        $logger,
          {
            event => "notify_subscribed",
            self  => "N2",
            peer  => "N1",
            what  => "unsubscribe",
          };

        cmp_expected {
            undef $n2;
        }
        $logger,
          {
            event   => 'ChildWithDemolish::DEMOLISH',
            package => 'ChildWithDemolish',
            self    => 'N2',
          },
          {
            event  => 'unsubscribe',
            self   => 'N1',
            peer   => 'N2',
            events => ['%all%'],
          },
          {
            event   => 'ParentWithDemolish::DEMOLISH',
            package => 'ParentWithDemolish',
            self    => 'N2',
          };

    };

    subtest "class without DEMOLISH" => sub {

        my $logger = MyTest::Logger->new;

        my $n1 = ChildWithoutDemolish->new( name => 'N1', logger => $logger );
        my $n2 = ChildWithoutDemolish->new( name => 'N2', logger => $logger );

        cmp_expected {
            $n1->subscribe( $n2, 'unsubscribe' );
        }
        $logger,
          {
            event => "notify_subscribed",
            self  => "N2",
            peer  => "N1",
            what  => "unsubscribe",
          };

        cmp_expected {
            undef $n2;
        }
        $logger,
          {
            event  => 'unsubscribe',
            self   => 'N1',
            peer   => 'N2',
            events => ['%all%'],
          },
          {
            event   => 'ParentWithDemolish::DEMOLISH',
            package => 'ParentWithDemolish',
            self    => 'N2',
          };

    };

};

done_testing;

