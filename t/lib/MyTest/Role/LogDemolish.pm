package MyTest::Role::LogDemolish;

use Moo::Role;
use Scalar::Util qw( blessed );

requires 'logit';

before 'DEMOLISH' => sub {

    $_[0]->logit( package => blessed $_[0], event => 'DEMOLISH' );

};

1;
