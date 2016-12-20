package LoopWrap;

use Try::Tiny;
use Scalar::Util qw[ weaken ];
use Moo;
extends 'Loop';

my %seen;

around build_sub => sub {

    my $orig = shift;
    my ( $self, $emitter, $name ) = @_;
    my @args = @_;

    my $tag = $self->tag( $emitter, $name );

    my $sub = &$orig( @args );

    weaken $self;

    return sub {
        my ( $event ) = @_;

        $self->fail( $event )
           if $seen{$tag}++;

        my @args = @_;

        try     { $sub->( @args )    }
        catch   { die $_             }
        finally { delete $seen{$tag} };
    };
};

1;
