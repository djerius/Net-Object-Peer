# ABSTRACT: An object which contains a reference address
package Net::Object::Peer::RefAddr;

use strictures 2;

our $VERSION = '0.05';

use Scalar::Util qw[ refaddr ];
use namespace::clean;


use overload
  '0+' => sub {0 + ${ $_[0] }},

  '""' => sub { "${$_[0]}" },

  '+'  => sub { my ( $me, $you ) = @_;
		$$me + $you;
	    },

  '==' => sub { my ( $me, $you ) = @_;
		0+$me == 0+$you;
	    },

  'eq' => sub { my ( $me, $you ) = @_;
		"$me" eq "$you";
	    },
;

=begin pod_coverage

=head4 does

=end pod_coverage

=cut

*does = \&UNIVERSAL::DOES;

=method  new

  $obj = Net::Object::Peer::RefAddr->new( $reference | $refaddr );

=cut

sub new {

    my ( $class, $thing ) = @_;

    bless( \( ref $thing ? refaddr( $thing ) : $thing ), $class );
}

1;

# COPYRIGHT

__END__

=head1 DESCRIPTION

B<Net::Object::Peer::RefAddr> is a class whose only purpose is
to identify the contents as a refaddr.
