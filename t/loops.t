#! perl

use Test2::Bundle::Extended;

use Moo::Role ();

{
    package Loop;

    use Carp;

    use Moo;
    with 'Net::Object::Peer';

    sub default_events { qw[ loop ] }

    has count => (
        is      => 'rwp',
        default => 0,
    );

    sub _cb_loop {
        my $self = shift;

        croak( "loop not caught" )
          if $self->count;
        $self->_set_count( $self->count + 1 );
        $self->emit( 'loop' );
        $self->_set_count( 0 );
    }

}


subtest 'loops' => sub {

    my $e1 = Loop->new;
    my $e2 = Loop->new;


    $e1->subscribe( $e2, "loop" );
    $e2->subscribe( $e1, "loop" );

    # no loop detection
    like( dies { $e1->emit( 'loop' ) }, qr/loop not caught/, "loop not caught" );

};


{
    package LoopSafe;

    use Carp;

    use Scalar::Util qw[ refaddr ];
    use Sub::QuoteX::Utils qw[ quote_subs ];
    use Moo;
    extends 'Loop';

    my %seen;

    around build_sub => sub {

        my $orig = shift;
        my ( $self, $emitter, $name ) = @_;

        my $tag = join $;, $name, refaddr $self, refaddr $emitter;

        my %captures = (
            '$seen' => \\%seen,
            '$tag'  => \$tag,
        );

        return quote_subs( [
                q[ croak( "loop caught" ) if $seen->{$tag}++; ],
                capture => \%captures, local => 0
            ],
            [ &$orig, local => 0 ],
            [ q/delete $seen->{$tag};/, capture => \%captures, local => 0 ],
        );
    };

}

subtest 'loop safe' => sub {

    my $e1 = LoopSafe->new;
    my $e2 = LoopSafe->new;


    $e1->subscribe( $e2, "loop" );
    $e2->subscribe( $e1, "loop" );

    # no loop detection
    like( dies { $e1->emit( 'loop' ) }, qr/loop caught/, "loop caught" );

};



done_testing;
