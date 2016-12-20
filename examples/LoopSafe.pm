package LoopSafe {

    use Carp;

    use Scalar::Util qw[ refaddr ];
    use Sub::QuoteX::Utils qw[ quote_subs ];
    use Moo;
    extends 'Loop';

    my %seen;

    around build_sub => sub {

        my $orig = shift;
        my ( $self, $emitter, $name ) = @_;

        my $tag = join $;, $name, refaddr $self, refaddr $peer;

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
