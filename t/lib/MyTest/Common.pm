#! perl

use Data::Dumper;
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

        $ok += 0 + is( $got, $expected, join( '; ', _label( $expected ) ) );
    }

    $ctx->release;

    return $ok == $n;
}

sub cmp_expected_unordered (&$@) {

    my ( $sub, $logger ) = ( shift, shift );

    my $ctx = context();

    $logger->clear;
    $sub->();
    my @got = $logger->dump;

    my @args     = @_;
    my $expected = bag {
        item( $_ ) foreach @args;
        end();
    };

    my $ok = 0 + is( \@got, $expected, _label( @_ ), 
		     "got:\n", Dumper(\@got),
		     "expected:\n", Dumper( \@_) );

    $ctx->release;

    return $ok;
}

sub _label {

    join ' && ', map {

        join ';',
          (
            "self: $_->{self}",
            ( exists $_->{peer} ? "peer: $_->{peer}" : () ),
            "event: $_->{event}",
            (
                exists $_->{events}
                ? "events : " . join( ',', @{ $_->{events} } )
                : ()
            ),
          )
      }

      @_;

}

1;
