#!/usr/bin/perl

package NodeA;

use Moo;
extends 'Node';

sub doit { $_[0]->emit( 'A' ) }

1;
