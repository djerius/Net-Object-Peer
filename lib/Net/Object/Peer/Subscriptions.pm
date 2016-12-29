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

=cut

sub list {
    return @{ $_[0]->_subscriptions };
}

=method clear

=cut

sub clear { $_[0]->_clear_subscriptions }

=method add

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

=method delete

=cut

sub delete {

    my $self = shift;

    my $subs = $self->_subscriptions;

    # need to remove subscriptions from the back to front,
    # or indices get messed up
    my @indices = reverse sort $self->_find_index( @_ );

    return map { splice( @$subs, $_, 1 ) } @indices;

}

1;
# COPYRIGHT

__END__

=head1 DESCRIPTION

A B<Net::Object::Peer::Subscriptions> object manages a collection
of L<Net::Object::Peer::Subscriptions> objects.
