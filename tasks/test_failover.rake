desc "Start an infinite publish/subscribe loop to test STOMP client failover"
task :test_failover do
  require 'klomp'

  # Set the delay between publish events. If this is too small, the consumer
  # will never be able to catch up to the producer, giving the false impression
  # of lost messages.
  publish_interval = 0.01

  client = Klomp::Client.new([
    'stomp://admin:password@localhost:61613',
    'stomp://admin:password@127.0.0.1:62613'
  ]).connect

  last_i = nil
  client.subscribe("/queue/test") do |msg|
    print "-"
    last_i = msg.body.to_i
  end

  begin
    i = 0
    loop do
      i += 1
      client.send("/queue/test", i.to_s) do |r|
        print "+"
      end
      sleep publish_interval
    end
  rescue SignalException
    client.disconnect
    puts
    puts "Sent #{i}; Received #{last_i}; Lost #{i - last_i}"
  end
end
