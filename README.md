# Klomp

Klomp is a simple wrapper around the [Stomp](https://github.com/stompgem/stomp)
and [OnStomp](https://github.com/meadvillerb/onstomp/) libraries with some
additional HA and usability features:

* When initialized with multiple broker URIs, Klomp will publish messages to
one broker at a time, but will consume from all brokers simultaneously. This is
a slight improvement over traditional failover clients that work by publishing
and subscribing through a single "active" broker. This one-broker-at-a-time
technique can lead to a split-brain scenario in which messages are only
received by a subset of your STOMP clients. By consuming from all brokers
simultaneously, Klomp ensures that no message is left behind.

* Where applicable, message bodies are automatically translated between native
Ruby and JSON objects.

* If a reply-to header is found in a message, a response is automatically
sent to the reply-to destination. The response will be the return value of the
subscribe block.

## Installation

    gem install klomp

## Example usage

The goal is that you should be able to use most (if not all) of the standard
Stomp/OnStomp APIs via a `Klomp::Client`:

    client = Klomp::Client.new([ ... ])

However, there will be some differences in the API due to how `Klomp::Client`
manages connections. For example, while OnStomp's `connected?` method normally
returns a single boolean value, Klomp's `connected?` will return many booleans
(i.e. one result for each broker).

### Fibonacci back-off retry behavior

The OnStomp failover client takes `:retry_attempts` and `:retry_delay` options,
and Klomp supports these too. However, if you do not specify either of these
values, Klomp's default behavior will be to try to reconnect indefinitely, but
use a fibonacci backoff approach, i.e., it will wait `fib(N)` seconds before
trying to reconnect on the Nth attempt.

### Message IDs

Klomp uses the `uuid` gem to generate per-message unique identifiers. To disable
generated message IDs, pass `:uuid => false` in the options hash. To customize
to use your own generator, simply pass `:uuid => object` where the object you
pass implements a `#generate` method that returns a string ID.

### Additional options for Klomp::Client

<table>
  <tr>
    <th>Key</th>
    <th>Default value</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>:translate_json</td>
    <td>true</td>
    <td>Translate message bodies between native Ruby and JSON objects?</td>
  </tr>
  <tr>
    <td>:auto_reply_to</td>
    <td>true</td>
    <td>Automatically send response to reply-to destination?</td>
  </tr>
  <tr>
    <td>:logger</td>
    <td>false</td>
    <td>Logger object</td>
  </tr>
  <tr>
    <td>:uuid</td>
    <td>UUID.new</td>
    <td>UUID generator object, responds to :generate and returns an ID</td>
  </tr>
</table>

## Developers

Set up the environment using `bundle install`. Note that the tests currently
assume a specific Apollo configuration which can be created on OSX using the
following commands:

    brew install apollo
    apollo create /usr/local/var/apollo-primary
    apollo create /usr/local/var/apollo-secondary
    sed -i -e 's/616/626/' /usr/local/var/apollo-secondary/etc/apollo.xml

Once Apollo is configured, the brokers can be started via `foreman start`. Now
you can run the test suite via `rake test` or `autotest`.

In addition to the regular test suite, there is a rake task called
"test_failover" that will start an infinite publish/subscribe loop. Once this
task is running, you can randomly kill Apollo brokers to test STOMP client
failover.

## Change Log

See the [ChangeLog file](/livingsocial/klomp/blob/master/ChangeLog.md).

## License

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

## Credits

* [Michael Paul Thomas Conigliaro](http://conigliaro.org): Original author
