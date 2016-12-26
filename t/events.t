#! perl

use 5.10.0;
use strict;
use warnings;

use Test2::Bundle::Extended;

use Net::Object::Peer;

my @got;
my @expected;

use Test2::API qw[ context ];

sub cmp_expected (&@) {

    my ( $sub, @expected ) = @_;

    my $ctx = context();

    @got = ();
    $sub->();


    my $ok = 0;

    my $n = @got > @expected ? @got : @expected;

    for my $idx ( 0 .. $n - 1 ) {

        my $got      = $got[$idx];
        my $expected = $expected[$idx];

        my @label = (
            "self: $expected->{self}",
            ( exists $expected->{peer} ? "peer: $expected->{peer}" : () ),
            "event: $expected->{event}"
        );

        $ok += 0 + is( $got, $expected, join( '; ', @label ) );
    }

    $ctx->release;

    return $ok == $n;

}

{
    package Node;

    use Moo;

    with 'Net::Object::Peer';

    has name => ( is => 'ro', required => 1 );

    sub _event {
        my $up = shift || 2;
        my $caller = ( caller( $up ) )[3];
        $caller =~ s/@{[__PACKAGE__]}::_(cb_|)//;
        return $caller;
    }

    sub logit {

        my $self = shift;

        push @got,
          {
            event => _event(),
            self  => $self->name,
            @_
          };
    }


    sub _notify_subscribed {

        my ( $self, $peer, @names ) = @_;

        $self->logit(
            peer => $peer->name,
            what => ( @names > 1 ? \@names : $names[0] ),
        );

    }

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

    sub _cb_unsubscribe {

        my ( $self, $event ) = @_;

        if ( $event->isa( 'Net::Object::Peer::UnsubscribeEvent' ) ) {

            $self->logit(
                peer   => $event->emitter->name,
                events => $event->event_names,
            );
        }

        else {

            $self->logit( peer => $event->emitter->name );

        }

    }

}

subtest "unsubscribe all" => sub {

    @got = @expected = ();

    my $n1 = Node->new( name => 'N1' );
    my $n2 = Node->new( name => 'N2' );
    my $n3 = Node->new( name => 'N3' );


    cmp_expected { $n2->subscribe( $n1, 'echo', 'changed' ) }
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N2",
        what  => [ "echo", "changed" ],
    };

    cmp_expected {
        $n3->subscribe( $n1, 'echo' )
    }
    {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => "echo"
    };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
    {
        event => "echo",
        self  => "N2",
        args  => [qw[ hello there ]],
    },
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    # subscribe n2 to another object (n3)
    cmp_expected { $n2->subscribe( $n3, 'changed' ) }
    {
        event => "notify_subscribed",
        self  => "N3",
        peer  => "N2",
        what  => "changed",
    };

    # and check that
    cmp_expected { $n3->emit( 'changed' ) }
    {
        event => "changed",
        self  => "N2",
        peer  => "N3",
    };

    cmp_expected { $n2->unsubscribe };

    # no output from n2
    cmp_expected { $n3->emit( 'changed' ) };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
    # no output from n2
    {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
    };


};

subtest "unsubscribe from events" => sub {

    @got = @expected = ();

    my $n1 = Node->new( name => 'N1' );
    my $n2 = Node->new( name => 'N2' );
    my $n3 = Node->new( name => 'N3' );

    # n3 follows both n1 and n2, events echo & changed
    cmp_expected { $n3->subscribe( $n1, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    cmp_expected { $n3->subscribe( $n2, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    # check things work
    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n2->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N2",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    # now n3 doesn't want to hear about echos from anyone
    cmp_expected { $n3->unsubscribe( 'echo' ) };

    # crickets
    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) };
    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) };

};

subtest "unsubscribe from peer" => sub {

    @got = @expected = ();

    my $n1 = Node->new( name => 'N1' );
    my $n2 = Node->new( name => 'N2' );
    my $n3 = Node->new( name => 'N3' );

    # n3 follows both n1 and n2, events echo & changed
    cmp_expected { $n3->subscribe( $n1, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    cmp_expected { $n3->subscribe( $n2, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    # check things work
    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n2->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N2",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    # now n3 doesn't want to hear from n2
    cmp_expected { $n3->unsubscribe( $n2 ) };

    # crickets
    cmp_expected { $n2->emit( 'changed' ) };
    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) };

    # but hear n1 load an clear
    # check things work
    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

};


subtest "unsubscribe from peer's events" => sub {

    @got = @expected = ();

    my $n1 = Node->new( name => 'N1' );
    my $n2 = Node->new( name => 'N2' );
    my $n3 = Node->new( name => 'N3' );

    # n3 follows both n1 and n2, events echo & changed
    cmp_expected { $n3->subscribe( $n1, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N1",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    cmp_expected { $n3->subscribe( $n2, 'echo', 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N3",
        what  => [ "echo", "changed" ],
      };

    # check things work
    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n2->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N2",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    # now n3 doesn't want to hear if n2 changed
    cmp_expected { $n3->unsubscribe( $n2, 'changed' ) };

    # crickets
    cmp_expected { $n2->emit( 'changed' ) };

    # but these still work
    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };

    # now add changed back,
    cmp_expected { $n3->subscribe( $n2, 'changed' ) }
      {
        event => "notify_subscribed",
        self  => "N2",
        peer  => "N3",
        what  => "changed",
      };

    # check if it still works
    cmp_expected { $n2->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N2",
      };


    # now n3 doesn't want to hear either event.
    # list them explicitly
    cmp_expected { $n3->unsubscribe( $n2, 'changed', 'echo' ) };

    # crickets
    cmp_expected { $n2->emit( 'changed' ) };
    cmp_expected { $n2->emit_args( echo => qw[ hello there ] ) };

    # but these still work
    cmp_expected { $n1->emit( 'changed' ) }
      {
        event => "changed",
        self  => "N3",
        peer  => "N1",
      };

    cmp_expected { $n1->emit_args( echo => qw[ hello there ] ) }
      {
        event => "echo",
        self  => "N3",
        args  => [qw[ hello there ]],
      };
};


# subtest "mix it up" => sub {

#     @got = @expected = ();

#     my $n1 = Node->new( name => 'N1' );
#     my $n2 = Node->new( name => 'N2' );
#     my $n3 = Node->new( name => 'N3' );
#     my $n4 = Node->new( name => 'N4' );

#     # n1 will follow n2's changes (and re-emit the event );
#     $n1->subscribe( $n2, 'changed' );
#     push @expected,
#       {
#         event => "notify_subscribed",
#         self  => "N2",
#         peer  => "N1",
#         what  => "changed"
#       };

#     # n4 will also follow n2's changes (and re-emit the event );
#     $n4->subscribe( $n2, 'changed' );
#     push @expected,
#       {
#         event => "notify_subscribed",
#         self  => "N2",
#         peer  => "N4",
#         what  => "changed"
#       };

#     # n3 will follow n1's changes (and re-emit the event );
#     $n3->subscribe( $n1, 'changed' );
#     push @expected,
#       {
#         event => "notify_subscribed",
#         self  => "N1",
#         peer  => "N3",
#         what  => "changed"
#       };

#     # n2 will notice if n1 is unsubscribed from it
#     $n2->subscribe( $n1, 'unsubscribe' );
#     push @expected,
#       {
#         event => "notify_subscribed",
#         self  => "N1",
#         peer  => "N2",
#         what  => "unsubscribe"
#       };


#     # this will cause a cascade of changed events
#     $n2->emit( 'changed' );
#     push @expected,
#       {
#         event => "changed",
#         self  => "N1",
#         peer  => "N2",
#       };
#     push @expected,
#       {
#         event => "changed",
#         self  => "N3",
#         peer  => "N1",
#       };
#     push @expected,
#       {
#         event => "changed",
#         self  => "N4",
#         peer  => "N2",
#       };

#     # n2 wants to directly message n4
#     $n2->send( $n4, 'changed' );
#     push @expected,
#       {
#         event => "changed",
#         self  => "N4",
#         peer  => "N2",
#       };

#     # n1 doesn't care about n2 anymore
#     $n1->unsubscribe( $n2, 'changed' );
#     push @expected,
#       {
#         event  => "unsubscribe",
#         self   => "N2",
#         peer   => "N1",
#         events => [ "changed", ],
#       };

#     # but n4 still does
#     $n2->emit( 'changed' );
#     push @expected,
#       {
#         event => "changed",
#         self  => "N4",
#         peer  => "N2",
#       };

#     # n3 still follows n1
#     $n1->emit( 'changed' );
#     push @expected,
#       {
#         event => "changed",
#         self  => "N3",
#         peer  => "N1",
#       };

#     # now it doesn't.  Since n3 didn't subscribe to unsubscribe events
#     # from n1, expect no output
#     $n3->unsubscribe( $n1 );

#     # howling in the wilderness
#     $n1->emit( 'changed' );

#     cmp_deeply( \@got, \@expected )
#       or diag( explain \@got );

#     # force a loop; the change callback will send
#     # a changed event to subscribers, n4 already follows
#     # n2, make n2 follow n4
#     $n2->subscribe( $n4, 'changed' );


#     like(
#         exception { $n4->emit( 'changed' ) },
#         qr/loop on 'changed'/,
#         'loop detection worked'
#     );


# };



done_testing;
