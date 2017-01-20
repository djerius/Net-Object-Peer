#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::RefAddr;

class_api_ok(
    'Net::Object::Peer::RefAddr',
    qw[
	  does
	  new
      ],
);

done_testing;
