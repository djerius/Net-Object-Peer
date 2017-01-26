#!perl

use 5.10.0;
use strict;
use warnings;

use Test::Lib;
use Test2::Bundle::Extended;

use Net::Object::Peer;

{
    package C1;
    use Moo;
    with 'Net::Object::Peer';

    sub default_events { q[bad+boy+bad+boy] }
}

like( dies { C1->new },
    qr/bad\+boy\+bad\+boy/, "illegal name for event via default_events" );

like( dies { C1->new( events => q["hikup"] ) },
    qr/hikup/, "illegal name for event via constructor" );

{
    package C2;
    use Moo;
    with 'Net::Object::Peer';

    sub default_events { qw[ has_cb hasnt_cb ] }

    sub _cb_has_cb { }
}

subtest "event subscriptions" => sub {

    my $n1 = C2->new;
    my $n2 = C2->new;

    ok( lives { $n1->subscribe( $n2, 'has_cb' ) },
        "subscribe to valid event", );

    like(
        dies { $n1->subscribe( $n2, 'hasnt_cb' ) },
        qr/_cb_hasnt_cb/,
	"subscribe to valid event, but no handler",
    );

    like(
        dies { $n1->subscribe( $n2, 'not_an_event' ) },
        qr/does not emit event "not_an_event"/,
        "subscribe to invalid event",
    );

};


subtest "event emission" => sub {

    my $n1 = C2->new;
    my $n2 = C2->new;

    ok( lives { $n1->emit( 'has_cb' ) }, "emit valid event", );

    like( dies { $n1->emit( 'not_an_event' ) },
	qr/does not emit event/,
	"emit invalid event",
    );

    ok( lives { $n1->emit_args( 'has_cb' ) }, "emit_args valid event", );

    like( dies { $n1->emit_args( 'not_an_event' ) },
	qr/does not emit event/,
	"emit_args invalid event",
    );


    ok( lives { $n1->send( $n2, 'has_cb' ) }, "emit valid event", );

    like( dies { $n1->send( $n2, 'not_an_event' ) },
	qr/does not emit event/,
	"emit invalid event",
    );

    ok( lives { $n1->send_args( $n2, 'has_cb' ) }, "emit_args valid event", );

    like( dies { $n1->send_args( $n2, 'not_an_event' ) },
	qr/does not emit event/,
	"emit_args invalid event",
    );



};


done_testing;
