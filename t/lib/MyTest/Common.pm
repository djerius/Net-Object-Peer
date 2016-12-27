#! perl

use Test2::Bundle::Extended;

use Exporter 'import';

our @EXPORT = qw( cmp_expected );

sub cmp_expected (&$@) {

    my ( $sub, $logger ) = ( shift, shift );

    my $ctx = context();

    $logger->clear;
    $sub->();
    my @got = $logger->dump;

    my $ok = 0;

    my $n = @got > @_ ? @got : @_;

    for my $idx ( 0 .. $n - 1 ) {

        my $got      = $got[$idx];
        my $expected = $_[$idx];

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

1;
