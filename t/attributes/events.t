#! perl

use 5.10.0;
use strict;
use warnings;

use Test::Lib;
use Test2::Bundle::Extended;
use MyTest::Common;
use Scalar::Util qw[ refaddr ];
use Algorithm::Combinatorics qw[ subsets ];

use Net::Object::Peer;

{
    package Node1;

    use Moo;
    with 'Net::Object::Peer';
}

{
    package Node2;

    use Moo;
    with 'Net::Object::Peer';
    sub default_events { qw[ foo bar ] }
}


subtest "default events" => sub {

    my $n1 = Node1->new( name => 'N1' );

    is(
        [ $n1->events ],
        bag {
            item 'detach';
            item 'unsubscribed';
            end();
        },
        "default events"
    );
};


subtest "events via constructor" => sub {

    subtest 'scalar' => sub {

        my $n1 = Node1->new( name => 'N1', events => 'foo' );

        is(
            [ $n1->events ],
            bag {
                item 'detach';
                item 'unsubscribed';
                item 'foo';
                end();
            },
            "array of new events"
        );
    };

    subtest 'array' => sub {

        my $events = [qw( foo bar )];

        my $n1 = Node1->new( name => 'N1', events => $events );

        is(
            [ $n1->events ],
            bag {
                item 'detach';
                item 'unsubscribed';
                item 'foo';
                item 'bar';
                end();
            },
            "array of new events"
        );

        isnt(
            refaddr( $n1->events ),
            refaddr $events,
            "object made a copy of the events arrayref"
        );
    };
};

subtest "events via attribute setter" => sub {

    my $n1 = Node1->new( name => 'N1' );

    my $events = [qw( foo bar )];

    $n1->events( $events );
    is(
        [ $n1->events ],
        bag {
            item 'detach';
            item 'unsubscribed';
            item 'foo';
            item 'bar';
            end();
        },
        "array of new events"
    );

    isnt(
        refaddr( $n1->events ),
        refaddr $events,
        "object made a copy of the events arrayref"
    );

    $n1->events( 'scandalous' );
    is(
        [ $n1->events ],
        bag {
            item 'detach';
            item 'unsubscribed';
            item 'scandalous';
            end();
        },
        "scalar new event"
    );
};

subtest "events via class method " => sub {

    my $n1 = Node2->new( name => 'N1' );

    is(
        [ $n1->events ],
        bag {
            item 'detach';
            item 'unsubscribed';
            item 'foo';
            item 'bar';
            end();
        },
        "default events"
    );
};

subtest "check for events" => sub {

    my $n1 = Node2->new( name => 'N1' );


    my $iter = subsets( [ $n1->events ] );

    while ( my $s = $iter->next ) {

	next unless @$s;

	ok( $n1->emits_events( @$s ), join( ', ', @$s ) );
    }

    ok ( ! $n1->emits_events( 'non-existent-event' ), 'non-existant-event' );
    ok ( ! $n1->emits_events( 'detach', 'non-existent-event' ), 'non-existant-event + existant event' );

};


done_testing;
