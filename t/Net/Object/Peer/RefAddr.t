#! perl

use 5.10.0;
use strict;
use warnings;

use Test2::Bundle::Extended;

use Test::Lib;
use Scalar::Util qw[ refaddr ];

use Net::Object::Peer::RefAddr;

my @a;
my $a = \@a;

my @b;
my $b = \@b;

subtest "equality" => sub {
    {
        my $a1 = Net::Object::Peer::RefAddr->new( refaddr \@a );
        my $a2 = Net::Object::Peer::RefAddr->new( \@a );
        is( $a1, $a2, 'refaddr \@a == \@a' );
    }

    {
        my $a1 = Net::Object::Peer::RefAddr->new( refaddr \@a );
        my $a2 = Net::Object::Peer::RefAddr->new( $a );
        is( $a1, $a2, '\@a = $a' );
    }

    {
        my $a1 = Net::Object::Peer::RefAddr->new( $a );
        my $a2 = Net::Object::Peer::RefAddr->new( refaddr \@b );
        isnt( $a1, $a2, '$a != refaddr( \@b )' );
    }

};

subtest "operator" => sub {

    my $addr = refaddr( $a );
    my $a1 = Net::Object::Peer::RefAddr->new( \@a );

    ok ( $addr == $a1, "==" );


};

done_testing;

