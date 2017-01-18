package MyTest::Fixture::Subscriptions;

use Net::Object::Peer::Subscriptions;
use Net::Object::Peer::Subscription;

{
    package MyTest::Fixture::Subscriptions::Peer;
    use Moo;
    with 'Net::Object::Peer';
}

use constant Peer          => 'MyTest::Fixture::Subscriptions::Peer';
use constant Subscription  => 'Net::Object::Peer::Subscription';
use constant Subscriptions => 'Net::Object::Peer::Subscriptions';

use Moo;
use Scalar::Util qw[ weaken ];

has sls => (
    is      => 'rwp',
    lazy    => 1,
    clearer => 1,
    default => sub { $_[0]->_build_stuff->sls },
    handles => [qw( remove nelem list find )],
);

has peers => (
    is      => 'rwp',
    lazy    => 1,
    clearer => 1,
    default => sub { $_[0]->_build_stuff->peers },
);


has subs => (
    is      => 'rwp',
    lazy    => 1,
    clearer => 1,
    default => sub { $_[0]->_build_stuff->subs },
);

sub clearer {

    $_[0]->clear_subs;
    $_[0]->clear_peers;
    $_[0]->clear_sls;
}

sub _build_stuff {

    my $self = shift;

    my ( @peers, @subs );

    my $sls = Subscriptions->new;

    for my $idx ( 0, 0, 1, 1, 2, 3, 3 ) {

        push @peers, Peer->new;
        push @subs,  {
            name => $idx,
            peer => $peers[-1],
            # at the moment, the unsubscribe callback isn't
            # constrained to do anything related to unsubscription
            unsubscribe => sub { $idx }
        };
	weaken $subs[-1]{peer};

        $sls->add( $subs[-1] );

    }

    $self->_set_peers( \@peers );
    $self->_set_subs( \@subs );
    $self->_set_sls( $sls );

    return $self;
}

1;
