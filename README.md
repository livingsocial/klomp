# klomp

* http://github.com/livingsocial/klomp

## DESCRIPTION:

Klomp is a simple [STOMP] messaging client that keeps your sanity intact.

The [Stomp Dance] is described as a "drunken," "crazy," or "inspirited" dance in
the native Creek Indian language. Not unlike what one finds when one looks for
Ruby STOMP clients.

The purpose of Klomp is to be the simplest possible Stomp client. No
in-memory buffering of outgoing messages, no fanout subscriptions in-process, no
transactions, no complicated messaging patterns. No crazy dances.

[Stomp]: http://stomp.github.com/
[Stomp Dance]: http://en.wikipedia.org/wiki/Stomp_dance

## FEATURES:

```
dance = Klomp.new(["127.0.0.1:61613"], "login" => "mylogin", "passcode" => "mypassword")

dance.publish("/queue/klomp", "craziness")

# subscribe with a block that gets invoked for each message
dance.subscribe("/queue/klomp") do |msg|
  puts msg.body # => craziness
end

# subscribe with an object that gets #call'd
class Dancer
  def call(msg)
    puts msg.body
  end
end
# replaces previous subscribe block above
dance.subscribe("/queue/klomp", Dancer.new)
dance.unsubscribe("/queue/klomp")
```

## REQUIREMENTS / LIMITATIONS:

- Only supports [Stomp 1.1](http://stomp.github.com/stomp-specification-1.1.html)
- Only one subscription per queue per Klomp
- Only one handler object/block per queue. If you want to multi-dispatch a
  message, write your own dispatcher.
- Only supports the following frames:
  - CONNECT/CONNECTED (initial handshake)
  - SEND
  - SUBSCRIBE
  - UNSUBSCRIBE
  - DISCONNECT
  - MESSAGE
  - ERROR
- Not supported:
  - ACK/NACK
  - BEGIN/COMMIT/ABORT
  - RECEIPT
  - ack/receipt headers

## AUTHORS / LICENSE:

* Nick Sieger <nick.sieger@livingsocial.com>

The MIT License

(c) 2012 LivingSocial, Inc.

(put license text here)
