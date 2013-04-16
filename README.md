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

The API surface area is minimal. `Klomp#publish` and `Klomp#subscribe` are your
main endpoints.

```ruby
klomp = Klomp.new(["127.0.0.1:61613"], "login" => "mylogin", "passcode" => "mypassword")

klomp.publish("/queue/klomp", "sanity")

# subscribe with a block that gets invoked for each message
klomp.subscribe("/queue/klomp") do |msg|
  puts msg.body # => sanity
end

# subscribe with an object that gets #call'd
class Klompen
  def call(msg)
    puts msg.body
  end
end
# replaces previous subscribe block above
klomp.subscribe("/queue/klomp", Klompen.new)
klomp.unsubscribe("/queue/klomp")

# subscribe with custom headers
klomp.subscribe("/queue/klomp", Klompen.new, :persistent => :true)
klomp.subscribe("/queue/klomp", :persistent => :true) do ... end

klomp.disconnect
```

### Connecting

Connections are established when a `Klomp` object is constructed. Connections
can be established in several ways.

```ruby
# Pass a single string containing host:port
klomp = Klomp.new "localhost:61613"

# Authentication with 'login' and 'passcode'
klomp = Klomp.new "localhost:61613", "login" => "bob", "passcode" => "farmville"

# With a stomp:// URL
klomp = Klomp.new "stomp://bob:farmville@localhost:61613"
```

#### Load-balancing

Klomp can be used to load-balance and maintain connections to multiple broker
hosts, such that if one broker goes down, the remaining broker(s) will be used.
Each broker is expected to provide an identical list of queues. To ensure
delivery, all Stomp clients should be connected to all brokers in the
load-balancing scenario.

Publish semantics are slightly different than those for subscribe:

- *Publish*: Klomp will publish each message on a randomly-selected broker.
- *Subscribe*: each Klomp object subscribes to the provided queues on all hosts.

Load-balanced connections are achieved with an array of servers.

```ruby
klomp = Klomp.new ["broker-001:61613", "broker-002:61613"]
klomp = Klomp.new ["broker-001:61613", "broker-002:61613"], "login" => "bob", "passcode" => "farmville"
klomp = Klomp.new ["stomp://bob:farmville@broker-001:61613", "stomp://bob:farmville@broker-002:61613"]
```

#### Virtual hosts

Klomp can use the Stomp 1.1 "virtual host" feature in several ways.

```ruby
# additional name in colon-separated triple
klomp = Klomp.new "virtual-host:localhost:61613"
# host option in constructor
klomp = Klomp.new "localhost:61613", "host" => "virtual-host"
# host query parameter in stomp:// url
klomp = Klomp.new "stomp://bob:farmville@localhost:61613?host=virtual-host"
```

#### Automatic reconnect

If a Klomp connection experiences errors reading from or writing to its socket,
the connection will go into an "offline" state. A sentinel thread will be
started that attempts to reconnect periodically at Fibonacci back-off intervals.

#### Logging

Klomp accepts a `Logger` object in the constructor options hash.

```ruby
klomp = Klomp.new "localhost:61613", "logger" => Logger.new($stdout)
```

Background exceptions that occur in the subscriber thread as well as offline and
reconnect events will be logged at the `warn` level, while individual sent and
received message frames will be logged at the `debug` level.

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

## LICENSE:

The MIT License

Copyright (C) 2012 LivingSocial

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
