package LoopQuote;

use Scalar::Util qw[ weaken ];
use Sub::QuoteX::Utils qw[ quote_subs ];
use Moo;
extends 'Loop';

my %seen;

around build_sub => sub {

    my $orig = shift;
    my ( $self, $emitter, $name ) = @_;

    my $tag = $self->tag( $emitter, $name );

    my $sub = &$orig;

    weaken $self;

    my %captures = (
        '$seen'   => \\%seen,
        '$r_self' => \\$self,
        '$name'   => \$name,
        '$tag'    => \$tag,
    );

    return quote_subs(
        \q[
            use Try::Tiny;
            my $event = $_[0];
            $$r_self->fail( $event ) if $seen->{$tag}++;
            my @args = @_;
            try {
           ],
        [ $sub, local => 1, args => q[@args] ],
        \q[
            }
            catch { die $_ } finally { delete $seen->{$tag} };
          ],
        { capture => \%captures },
    );
};

1;
