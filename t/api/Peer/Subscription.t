#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::Subscription;

class_api_ok(
    'Net::Object::Peer::Subscription',
    qw[
      DOES
      as_hashref
      name
      new
      peer
      unsubscribe
      ],
);

done_testing;
