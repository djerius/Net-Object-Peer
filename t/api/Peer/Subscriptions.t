#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use Net::Object::Peer::Subscriptions;

class_api_ok(
    'Net::Object::Peer::Subscriptions',
    qw[
      DOES
      add
      after
      around
      before
      extends
      find
      nelem
      has
      list
      new
      remove
      with
      ],
);

done_testing;
