#! perl

use 5.10.0;
use strict;
use warnings;

use Test2::Bundle::Extended;

use Test::Lib;
use Scalar::Util qw[ refaddr ];

use MyTest::Fixture::Subscriptions;

sub cmp_subscription ( $$ ) {

    my ( $sub1, $sub2 ) = @_;

    my $ctx = context();

    my $ok
      = is( $sub1->{name},        $sub2->{name},        "name" )
      + is( $sub1->{peer},        $sub2->{peer},        "peer" )
	;

    $ctx->release;

    return $ok == 3;
}

subtest remove => sub {

    subtest 'single sub' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->remove( sub { $_[0]->name == 2 } );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 6, "number remaining" );
	    cmp_subscription( ($fix->list)[4], $fix->subs->[5] );
        };

	subtest 'removed element' => sub {
	    is( scalar @del, 1, "number" );
	    cmp_subscription( $del[0], $fix->subs->[4] );
	};
    };

    subtest 'multiple @ start' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->remove( sub { $_[0]->name == 0 } );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[0], $fix->subs->[2] );
        };

	subtest 'removed elements' => sub {
	    is( scalar @del, 2, "number" );
	    cmp_subscription( $del[0], $fix->subs->[0] );
	    cmp_subscription( $del[1], $fix->subs->[1] );

	};
    };

    subtest 'multiple @ middle' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->remove( name => 1 );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[2], $fix->subs->[4] );
        };

	subtest 'removed elements' => sub {
	    is( scalar @del, 2, "number" );
	    cmp_subscription( $del[0], $fix->subs->[2] );
	    cmp_subscription( $del[1], $fix->subs->[3] );

	};
    };

    subtest 'multiple @ end' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->remove( name => 3 );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[4], $fix->subs->[4] );
        };

	subtest 'removed elements' => sub {
	    is( scalar @del, 2, "number" );
	    cmp_subscription( $del[0], $fix->subs->[5] );
	    cmp_subscription( $del[1], $fix->subs->[6] );

	};
    };

};

subtest find => sub {

    my $fix = MyTest::Fixture::Subscriptions->new;


    subtest 'single sub' => sub {

        my @found = $fix->find( sub { $_[0]->name == 2 } );

	subtest 'found element' => sub {
	    is( scalar @found, 1, "number" );
	    cmp_subscription( $found[0], $fix->subs->[4] );
	};
    };

    subtest 'multiple @ start' => sub {

        my @found = $fix->find( sub { $_[0]->name == 0 } );

	subtest 'found elements' => sub {
	    is( scalar @found, 2, "number" );
	    cmp_subscription( $found[0], $fix->subs->[0] );
	    cmp_subscription( $found[1], $fix->subs->[1] );

	};
    };

    subtest 'multiple @ middle' => sub {

        my @found = $fix->find( name => 1 );

	subtest 'found elements' => sub {
	    is( scalar @found, 2, "number" );
	    cmp_subscription( $found[0], $fix->subs->[2] );
	    cmp_subscription( $found[1], $fix->subs->[3] );

	};
    };

    subtest 'multiple @ end' => sub {

        my @found = $fix->find( name => 3 );

	subtest 'found elements' => sub {
	    is( scalar @found, 2, "number" );
	    cmp_subscription( $found[0], $fix->subs->[5] );
	    cmp_subscription( $found[1], $fix->subs->[6] );

	};
    };

};

subtest 'vanishing subscription' => sub {

    my $fix = MyTest::Fixture::Subscriptions->new;

    # zap one of the peers.
    my $addr = refaddr $fix->peers->[-1];
    undef $fix->peers->[-1];

    # first verify that the deletion percolated into the subscription list
    my @found = $fix->find( sub { ! defined $_[0]->peer } );
    is( scalar @found, 1, "found 1 deletion" );

    is( $found[0]{addr}, $addr, "deleted sub has correct peer addr" );

    # now check that this doesn't croak because of undefined values
    ok( lives { $fix->find( peer => 'ffo' ) }, "ignore undefined in hash match" );

};

done_testing;

