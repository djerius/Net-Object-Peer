package MyTest::Role::Log;

use Types::Standard 'InstanceOf';

use Moo::Role;

has logger => (
    is       => 'ro',
    isa      => InstanceOf ['MyTest::Logger'],
    required => 1
);

1;
