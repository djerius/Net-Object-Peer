package MyTest::Logger;

sub new {

    my $class = shift;

    bless [], $class;
}

sub log {

    my $self = shift;
    push @$self, @_;
}

sub clear {

    @{$_[0]} = ();

}

sub dump {

    return @{ $_[0] };

}

1;
