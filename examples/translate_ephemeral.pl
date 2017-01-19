#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use lib 'examples/translate';

use NodeA;
use NodeB;

use TranslateBtoAEphemeral;

my $nA = NodeA->new;
my $nB = NodeB->new;

$nA->subscribe( TranslateBtoAEphemeral->new( proxy_for => $nB ), 'A', 'detach' );

$nB->doit;

