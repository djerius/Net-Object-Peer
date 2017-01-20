# ABSTRACT: Proxy role for ephemeal peers
package Net::Object::Peer::Ephemeral;

use Moo::Role;

our $VERSION = '0.05';

1;

# COPYRIGHT

__END__

=head1 SYNTAX

  # in class which will act as an intermediate/proxy
  package Ephemeral;
  with 'Net::Object::Peer::Ephemeral';

  [...]

=head1 DESCRIPTION

This role's sole purpose is to inform a subscriber that the emitter is
ephemeral (e.g., will disappear without an additional reference) and
it should keep track of it.  Normally only weak references to emittes
are kept, so as to prevent them outliving their intended scope.

Sometimes, however, it is necessary that the emitter outlive its
scope.  For example, assume that C<$subscriber> expects event C<A> to
be emitted when some condition has been met by C<$emitter>, but
C<$emitter> actually emits C<B>.  C<$subscriber> could tie
C<$emitter>'s C<B> event to it's own C<B> callback, but if
C<$subscriber> searches its subscriptions for C<A> event emitters,
it won't find this one.

One workaround is to create a proxy object which subscribes to
C<$emitter>'s C<B> event and re-emits it (with C<$emitter> as the
emitter) as event C<A>.  How does one keep that object alive?  Typically
it would be created on the fly when passed to the subscriber, e.g.

  $subscriber->subscribe( Translator->new( emitter => $emitter,
                                      from => C<B>, to => C<A> ),
                                      C<A> );

If C<$subscriber> doesn't hold on to the proxy object, it will be
destroyed immediately after the subscription, and the whole process fails.

Instead, if C<Translator> consumes the C<Net::Ojbect::Peer::Ephemeral>
role, C<$subscriber> will ensure it is not destroyed by holding strong
reference to it.  In this example, C<Translator> should subscribe to
the C<$emitter>'s C<detach> event so that it can detach itself from
C<$subscriber> and thus be destroyed.
