#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'examples/translate';
use NodeA;
use NodeB;

use TranslateBtoA;

my $nA = NodeA->new;
my $nB = NodeB->new;

my $xlate = TranslateBtoA->new( proxy_for => $nB );
$nA->subscribe( $xlate, 'A' );

$nB->doit;

