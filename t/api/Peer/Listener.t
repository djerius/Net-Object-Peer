#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::Listener;

class_api_ok(
    'Net::Object::Peer::Listener',
    qw[
      DOES
      after
      around
      before
      extends
      has
      new
      peer
      with
      ],
);

done_testing;
