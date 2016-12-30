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
      after
      around
      as_hashref
      before
      extends
      has
      name
      new
      peer
      unsubscribe
      with
      ],
);

done_testing;
