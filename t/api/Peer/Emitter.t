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
      emit
      emit_args
      listeners
      new
      on
      send
      send_args
      subscribe
      un
      unsubscribe
      ],
);

done_testing;
