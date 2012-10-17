require 'spec_helper'
require 'em-proxy'
require 'logger'

describe "Klomp reconnect logic", :acceptance => true do

  include_context :acceptance_client
  Given(:origin_server) { "127.0.0.1:61613" }
  Given(:server) { "127.0.0.1:62623" }
  Given(:options) { Hash[*%w(login passcode).zip(credentials).flatten] }

  it "reconnects after a server goes down" do
    # Publish and receive a message
    klomp.publish "/queue/greeting", "hello"
    incoming = []
    klomp.subscribe "/queue/greeting" do |msg|
      incoming << msg
    end
    sleep 2
    incoming.should_not be_empty

    # Server disappears
    stop_proxy
    expect { klomp.publish "/queue/greeting", "hello" }.to raise_error
    klomp.should_not be_connected

    # Server reappears
    start_proxy
    klomp.should be_connected

    # Subscription is re-established
    incoming = []
    klomp.publish "/queue/greeting", "hello"
    sleep 2
    incoming.should_not be_empty

    klomp.unsubscribe "/queue/greeting"
  end

  before { start_proxy }
  after { stop_proxy }

  def server_to_hash(s)
    Hash[*[:host, :port].zip(s.split(':')).flatten]
  end

  def start_proxy
    listen, forward = server_to_hash(server), server_to_hash(origin_server)
    @pid = fork do
      [STDIN, STDOUT, STDERR].each {|s| s.reopen "/dev/null" }
      Proxy.start listen do |conn|
        conn.server :origin, forward.merge(:relay_client => true, :relay_server => true)
      end
    end
    sleep 2
  end

  def stop_proxy
    if @pid
      Process.kill "TERM", @pid
      @pid = nil
      sleep 1
    end
  end

end
