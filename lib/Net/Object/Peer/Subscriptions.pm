# ABSTRACT: A collection of Net::Object::Peer::Subscriptions
package Net::Object::Peer::Subscriptions;

use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.04';

use Types::Standard qw[ ArrayRef InstanceOf ];
use Ref::Util qw[ is_coderef ];
use List::Util qw[ all ];

use namespace::clean;

use Moo;

has _subscriptions => (
    is       => 'ro',
    init_arg => undef,
    isa      => ArrayRef [ InstanceOf ['Net::Object::Peer::Subscription'] ],
    default => sub { [] },
    lazy    => 1,
    clearer => 1,
);

=method list

  @subs = $subs->list;

return the list of subscriptions.

=cut

sub list {
    return @{ $_[0]->_subscriptions };
}

=method nelem

  $nelem = $subs->nelem;

return the number of elements in the list of subscriptions.

=cut

sub nelem {
    return scalar @{ $_[0]->_subscriptions };
}

=method clear

  $subs->clear;

clear out the list of subscriptions

=cut

sub clear { $_[0]->_clear_subscriptions }

=method add

  $subs->add( @subscriptions );

add one or more subscriptions.  They must be of class L<Net::Object::Peer::Subscription>;

=cut

sub add {
    my $self = shift;

    push @{ $self->_subscriptions }, @_;

    return;
}

sub _find_index {

    my $self = shift;
    my $subs = $self->_subscriptions;

    if ( is_coderef( $_[0] ) ) {

        my $match = shift;
        return grep { $match->( $subs->[$_] ) } 0 .. @$subs - 1;

    }
    else {
        my %match = @_;

        return grep {
            my $sub = $subs->[$_];
            all { $sub->$_ eq $match{$_} } keys %match;
        } 0 .. @$subs - 1;
    }
}

=method find

  my @subs = $subs->find( $coderef | %spec );

Return subscriptions which match the passed arguments.

A single argument must be a coderef; it will be invoked with a
L<Net::Peer::Subscription> object as an argument.  It should return
true if it matches, false otherwise.

If a hash is passed, its values are compared to the attributes of
subscriptions in the list.

=cut

sub find {

    my $self = shift;

    my $subs = $self->_subscriptions;

    my @indices = $self->_find_index( @_ );

    return @{$subs}[ @indices ];
}


=method delete

  @subs = $subs->delete( $coderef | %spec );

Delete and the matching subscriptions (see L</find> for the meaning
of the arguments).


=cut

sub delete {

    my $self = shift;

    my $subs = $self->_subscriptions;

    # need to remove subscriptions from the back to front,
    # or indices get messed up
    my @indices = reverse sort $self->_find_index( @_ );

    return reverse map { splice( @$subs, $_, 1 ) } @indices;

}

1;
# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscriptions> object manages a collection
of L<Net::Object::Peer::Subscriptions> objects.
