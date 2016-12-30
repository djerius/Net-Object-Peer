#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Moo;
with 'Net::Object::Peer';

class_api_ok(
    'Net::Object::Peer',
    qw[
      DOES
      build_sub
      detach
      emit
      emit_args
      send
      send_args
      subscribe
      subscriptions
      unsubscribe
      ] );

done_testing;
