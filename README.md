# klomp

* http://github.com/livingsocial/klomp

## DESCRIPTION:

Klomp is a simple [Stomp] messaging client that keeps your sanity intact.

The purpose of Klomp is to be the simplest possible Stomp client. No in-memory
buffering of outgoing messages, no fanout subscriptions in-process, no
transactions, no complicated messaging patterns. Code simple enough so that when
something goes wrong, the problem is obvious.

[Stomp]: http://stomp.github.com/

## FEATURES:

```
klomp = Klomp.new(["127.0.0.1:61613"], "login" => "mylogin", "passcode" => "mypassword")

dance.publish("/queue/klomp", "sanity")

# subscribe with a block that gets invoked for each message
klomp.subscribe("/queue/klomp") do |msg|
  puts msg.body # => sanity
end

# subscribe with an object that gets #call'd
class Klompen
  Def call(msg)
    puts msg.body
  end
end
# replaces previous subscribe block above
klomp.subscribe("/queue/klomp", Klompen.new)
klomp.unsubscribe("/queue/klomp")
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
