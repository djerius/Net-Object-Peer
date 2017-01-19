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

$nA->subscribe( TranslateBtoA->new( proxy_for => $nB ), 'A' );

$nB->doit;

