package Loop;

use Carp;
our @CARP_NOT = qw( Beam::Emitter );

use Try::Tiny;
use Scalar::Util qw[ refaddr ];

use Moo;
use MooX::ClassAttribute;

with 'Net::Object::Peer';

has seen     => ( is => 'ro', default  => sub { {} } );
has name     => ( is => 'ro', required => 1          );

# Set high so can verify there is a loop
class_has
    max_seen => ( is => 'rw', default =>  5          );

sub label {
    my ( $self, $emitter, $name ) = @_;
    qq/@{[$self->name]} got '$name' from @{[$emitter->name]}/;
}

sub fail {
    my ( $self, $event ) = @_;
    croak( "loop detected: ",
	   $self->label( $event->emitter, $event->name ) );
}

sub tag {
    my ( $self, $emitter, $name ) = @_;
    join $;, $name, refaddr $self, refaddr $emitter;
}

sub _cb_signal {
    my ( $self, $event ) = @_;

    my $tag = $self->tag( $event->emitter, $event->name );

    $self->fail( $event )
      if $self->seen->{$tag}++ == $self->max_seen;

    print $self->label( $event->emitter, $event->name ), "\n";

    try    { $self->emit( $event->name ) }
    catch  { die $_                      }
    finally{ delete $self->seen->{$tag}  };
}

1;
