#!/usr/bin/perl

package NodeB;

use Moo;
extends 'Node';

sub doit { $_[0]->emit( 'B' ) }

1;
