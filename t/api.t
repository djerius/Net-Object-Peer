#! perl

use 5.10.0;
use Sub::Quote;
use Moo::Role ();

use Test2::Bundle::Extended;

{
    package Node;
    use Moo;

    with 'Net::Object::Peer';

    sub default_events { qw[ signal ] }

    has _stash => (
        is        => 'ro',
        init_args => undef,
        default   => sub { [] },
        clearer   => 1,
        lazy      => 1,
    );

    sub stash {

        my $self = shift;

        push @{ $self->_stash }, @_;

        return $self->_stash;
    }

    sub _cb_signal {
        $_[0]->stash( '_cb_signal' );
    }

    sub method {
        $_[0]->stash( 'method' );
    }

}

{
    package BuildSub;

    use Moo::Role;
    use Sub::QuoteX::Utils qw< quote_subs >;

    around build_sub => sub {

        my $orig = shift;
        my $self = $_[0];

        my $sub = &$orig;

        quote_subs(
            [ $self, 'stash', args => ['before'] ],
            $sub, [ $self, 'stash', args => ['after'] ],
        );
    };
}

sub test_subscribe {

    my %option = 'HASH' eq ref $_[-1] ? %{ pop @_ } : ();

    my @n = @_;

    my $ctx = context();

    my $mdx = sub { [@_] };

    $n[1]->subscribe( $n[0], 'signal' );
    $n[2]->subscribe( $n[0],
        signal => quote_sub( q[$n2->stash("quoted")], { '$n2' => \$n[2] } ), );

    $n[3]->subscribe( $n[0], signal => { method => "method" } );
    $n[4]->subscribe( $n[0], signal => sub { $n[4]->stash( "coderef" ) } );

    $n[0]->emit( 'signal' );

    is( $n[1]->stash, $mdx->( '_cb_signal' ), 'default method' );
    is( $n[2]->stash, $mdx->( 'quoted' ),     'quoted sub' );
    is( $n[3]->stash, $mdx->( 'method' ),     'named method' );
    is( $n[4]->stash, $mdx->( 'coderef' ),    'coderef' );

    # resubscribe each node object with a different action.
    # this tests that the original actions are unsubscribed.

    $_->_clear_stash for @n;

    $n[4]->subscribe( $n[0], 'signal' );
    $n[3]->subscribe( $n[0],
        signal => quote_sub( q[$n3->stash("quoted")], { '$n3' => \$n[3] } ), );

    $n[2]->subscribe( $n[0], signal => { method => "method" } );
    $n[1]->subscribe( $n[0], signal => sub { $n[1]->stash( "coderef" ) } );

    $n[0]->emit( 'signal' );

    is( $n[4]->stash, $mdx->( '_cb_signal' ), 'default method' );
    is( $n[3]->stash, $mdx->( 'quoted' ),     'quoted sub' );
    is( $n[2]->stash, $mdx->( 'method' ),     'named method' );
    is( $n[1]->stash, $mdx->( 'coderef' ),    'coderef' );

    $ctx->release;
}

subtest subscribe => sub {

    my @n = map { Node->new } 0 .. 4;

    test_subscribe( @n );
};

done_testing;
