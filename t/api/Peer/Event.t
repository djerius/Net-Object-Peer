#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::Event;

class_api_ok(
    'Net::Object::Peer::Event',
    qw[
      DOES
      addr
      after
      around
      before
      emitter
      extends
      has
      has_addr
      name
      new
      new
      with
      ] );
done_testing;
