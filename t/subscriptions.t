#! perl

use 5.10.0;
use strict;
use warnings;

use Test2::Bundle::Extended;

use Test::Lib;

use MyTest::Fixture::Subscriptions;

sub cmp_subscription ( $$ ) {

    my ( $sub1, $sub2 ) = @_;

    my $ctx = context();

    my $ok
      = is( $sub1->name,        $sub2->name,        "name" )
      + is( $sub1->peer,        $sub2->peer,        "peer" )
	# sneek a look at the real sub, not it's output
      + is( $sub1->_unsubscribe, $sub2->_unsubscribe, "unsubscribe" );

    $ctx->release;

    return $ok == 3;
}

subtest delete => sub {

    subtest 'single sub' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->delete( sub { $_[0]->name == 2 } );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 6, "number remaining" );
	    cmp_subscription( ($fix->list)[4], $fix->subs->[5] );
        };

	subtest 'deleted element' => sub {
	    is( scalar @del, 1, "number" );
	    cmp_subscription( $del[0], $fix->subs->[4] );
	};
    };

    subtest 'multiple @ start' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->delete( sub { $_[0]->name == 0 } );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[0], $fix->subs->[2] );
        };

	subtest 'deleted elements' => sub {
	    is( scalar @del, 2, "number" );
	    cmp_subscription( $del[0], $fix->subs->[0] );
	    cmp_subscription( $del[1], $fix->subs->[1] );

	};
    };

    subtest 'multiple @ middle' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->delete( name => 1 );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[2], $fix->subs->[4] );
        };

	subtest 'deleted elements' => sub {
	    is( scalar @del, 2, "number" );
	    cmp_subscription( $del[0], $fix->subs->[2] );
	    cmp_subscription( $del[1], $fix->subs->[3] );

	};
    };

    subtest 'multiple @ end' => sub {

	my $fix = MyTest::Fixture::Subscriptions->new;

        my @del = $fix->delete( name => 3 );

        subtest 'compacted list' => sub {
	    is( $fix->nelem, 5, "number remaining" );
	    cmp_subscription( ($fix->list)[4], $fix->subs->[4] );
        };

	subtest 'deleted elements' => sub {
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

done_testing;

