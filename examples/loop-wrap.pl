use lib 'examples';
use aliased 'LoopWrap' => 'Loop';

Loop->max_count( 10 );

my $n1 = Loop->new( 'n1' );
my $n2 = Loop->new( 'n2' );
my $n3 = Loop->new( 'n3' );


$n3->subscribe( $n1, "loop" );
$n3->subscribe( $n2, "loop" );
$n2->subscribe( $n3, "loop" );

# and start the ping-pong
$n1->emit( 'loop' );
