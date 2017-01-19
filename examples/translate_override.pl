#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'examples/translate';
use NodeA;
use NodeB;

my $nA = NodeA->new;
my $nB = NodeB->new;

$nA->subscribe( $nB, 'B' => { method => '_cb_A' } );

$nB->doit;
