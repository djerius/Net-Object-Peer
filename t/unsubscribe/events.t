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

    sub default_events { qw[ changed echo n1 n2 ] }

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

    sub _cb_n1 {}
    sub _cb_n2 {}
}

subtest "unsubscribe from events" => sub {

    my $logger = MyTest::Logger->new;

    my $n1 = Node->new( name => 'N1', logger => $logger );
    my $n2 = Node->new( name => 'N2', logger => $logger  );
    my $n3 = Node->new( name => 'N3', logger => $logger  );

    # n3 follows both n1 and n2, events echo & changed
    cmp_expected { $n3->subscribe( $n1, 'echo', 'changed', 'n1' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => [ "echo", "changed", "n1" ],
    };

    cmp_expected { $n3->subscribe( $n2, 'echo', 'changed', 'n2' ) }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N3",
        what  => [ "echo", "changed", "n2" ],
    };

    cmp_expected {
        $n1->subscribe( $n3, 'unsubscribed' )
    }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N3",
        peer  => "N1",
        what  => "unsubscribed",
    };

    cmp_expected {
        $n2->subscribe( $n3, 'unsubscribed' )
    }
    $logger,
    {
        event => "notify_subscribed",
        self  => "N3",
        peer  => "N2",
        what  => "unsubscribed",
    };

    # check things work
    cmp_expected { $n1->emit( 'changed' ) }
    $logger,
    {
        event => "changed",
        self  => "N3",
        peer  => "N1",
    };

    cmp_expected { $n2->emit( 'changed' ) }
    $logger,
    {
        event => "changed",
        self  => "N3",
        peer  => "N2",
    };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
    $logger,
    {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
    };

    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
    $logger,
    {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
    };

    # now n3 doesn't want to hear about echos from anyone
    cmp_expected_unordered { $n3->unsubscribe( 'echo' ) }
    $logger,
    {
        event => "unsubscribed",
        self  => "N1",
        peer  => "N3",
        events=> [ 'echo' ],
    },
    {
        event => "unsubscribed",
        self  => "N2",
        peer  => "N3",
        events=> [ 'echo' ],
    };

    # remove an event we know is from $n1
    cmp_expected { $n3->unsubscribe( 'n1' ) }
    $logger,
    {
        event => "unsubscribed",
        self  => "N1",
        peer  => "N3",
        events=> [ 'n1' ],
    };

    # remove an event we know is from $n2
    cmp_expected { $n3->unsubscribe( 'n2' ) }
    $logger,
    {
        event => "unsubscribed",
        self  => "N2",
        peer  => "N3",
        events=> [ 'n2' ],
    };

    # crickets
    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
    $logger,
    ;
    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
    $logger,
    ;

};

done_testing;
