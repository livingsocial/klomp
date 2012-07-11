require 'minitest/autorun'
require 'minitest/pride'

require 'klomp'
require File.expand_path('../test_helper', __FILE__)

describe Klomp::Client do

  include KlompTestHelpers

  before do
    @adapter = :onstomp
    @uris = [
      'stomp://admin:password@localhost:61613',
      'stomp://admin:password@127.0.0.1:62613'
    ]
    @destination = '/queue/test_component.test_event'
  end

  it "raises an error if authentication fails" do
    assert_raises OnStomp::ConnectFailedError do
      Klomp::Client.new(@uris.first.sub('password', 'psswrd'), :adapter => @adapter).connect
    end
  end

  it "sends heartbeat" do
    client = Klomp::Client.new(@uris, :adapter => @adapter).connect
    client.beat
    client.disconnect
  end

  it "unsubscribes" do
    client = Klomp::Client.new(@uris, :adapter => @adapter).connect

    subscribe_frames = client.subscribe(@destination) { |msg| }
    unsub_frames = client.unsubscribe(subscribe_frames)
    let_background_processor_run
    client.disconnect

    assert_equal subscribe_frames.length, unsub_frames.length
    assert client.subscriptions.flatten.empty?, "expected connection to have no subscriptions"
  end

  it 'uses a fibonacci back-off approach to reconnect' do
    good_client = Object.new
    def good_client.connect; true; end
    def good_client.connected?; true; end
    def good_client.connection; true; end

    bad_client = Object.new
    def bad_client.connect; raise "could not connect"; end
    def bad_client.connected?; false; end

    test_context = self
    attempts = 0
    conn = nil
    fib = lambda {|n| (1..n).inject([0, 1]) {|fib,_| [fib[1], fib[0]+fib[1]]}.first}

    pool_class = Class.new do
      def initialize(*) end
      def each(&blk) end
      define_method :next_client do
        attempts += 1
        test_context.assert_equal fib[attempts], conn.retry_delay
        if attempts == 6
          good_client
        else
          bad_client
        end
      end
    end

    client = Klomp::Client.new(@uris.first, :adapter => @adapter, :pool => pool_class)
    conn = client.write_conn
    def conn.sleep_for_retry(*) end # skip sleep between retries for test

    client.reconnect
    assert_equal 6, attempts
  end

end
