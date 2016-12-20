use Try::Tiny;

use lib 'examples';
use Module::Load;

my ( $class ) = @ARGV;

load $class;

my $n1 = $class->new( name => 'n1' );
my $n2 = $class->new( name => 'n2' );
my $n3 = $class->new( name => 'n3' );

$n3->subscribe( $n1, "signal" );
$n3->subscribe( $n2, "signal" );
$n2->subscribe( $n3, "signal" );

# and start the ping-pong
try {
    $n1->emit( 'signal' );
}
catch {
    print $_;
};
