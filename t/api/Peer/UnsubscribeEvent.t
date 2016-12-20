#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::UnsubscribeEvent;

class_api_ok(
    'Net::Object::Peer::UnsubscribeEvent',
    qw[
      DOES
      after
      around
      before
      extends
      event_names
      has
      new
      with
      ],
);

done_testing;
