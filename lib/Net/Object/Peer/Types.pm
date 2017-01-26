# ABSTRACT: Types for Net::Object::Peer
package Net::Object::Peer::Types;

use strict;
use warnings;

our $VERSION = '0.06';

use Type::Library
  -base,
  -declare => qw[ Identifier ];

use Type::Utils -all;
use Types::Standard -types;

declare Identifier,
as Str,
where { $_[0] !~ /\W/ };

1;
