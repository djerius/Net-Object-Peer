#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::Emitter;

class_api_ok(
    'Net::Object::Peer::Emitter',
    qw[
      DOES
      after
      around
      before
      emit
      emit_args
      extends
      has
      listeners
      new
      on
      send
      send_args
      subscribe
      un
      unsubscribe
      with
      ],
);

done_testing;
