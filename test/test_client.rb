require 'minitest/autorun'
require 'minitest/pride'

require 'klomp'
require File.expand_path('../test_helper', __FILE__)

describe Klomp::Client do

  include KlompTestHelpers

  before do
    @uris = [
      'stomp://admin:password@localhost:61613',
      'stomp://admin:password@127.0.0.1:62613'
    ]
    @destination = '/queue/test_component.test_event'
  end

  it 'accepts a single uri and establishes separate failover connections for writes and reads' do
    client = Klomp::Client.new(@uris.first).connect

    assert_equal [client.write_conn], client.read_conn
    assert client.write_conn.connected?

    client.disconnect
  end

  it 'accepts an array of uris and establishes separate failover connections for writes and reads' do
    client = Klomp::Client.new(@uris).connect

    assert client.write_conn.connected?
    refute_empty client.read_conn
    client.read_conn.each do |obj|
      assert obj.connected?
    end

    client.disconnect
  end

  it 'raises an error if authentication fails' do
    assert_raises OnStomp::ConnectFailedError do
      Klomp::Client.new(@uris.first.sub('password', 'psswrd')).connect
    end
  end

  it 'disconnnects' do
    client = Klomp::Client.new(@uris.first).connect
    assert client.write_conn.connected?
    client.disconnect
    refute client.write_conn.connected?
  end

  it 'has a logger' do
    logger = Logger.new(STDOUT)
    client = Klomp::Client.new(@uris, :logger=>logger).connect

    assert_equal client.log, logger

    client.disconnect
  end

  it 'sends heartbeat' do
    client = Klomp::Client.new(@uris).connect.beat
  end

  it 'sends requests and gets responses' do
    client = Klomp::Client.new(@uris).connect
    body  = { 'body' => rand(36**128).to_s(36) }

    client.send(@destination, body, :ack=>'client')

    got_message = false
    client.subscribe(@destination) do |msg|
      got_message = true if msg.body == body
      client.ack(msg)
    end
    let_background_processor_run
    assert got_message

    client.disconnect
  end

  it 'automatically publishes responses to the reply-to destination' do
    client        = Klomp::Client.new(@uris).connect
    reply_to_body = { 'reply_to_body' => rand(36**128).to_s(36) }

    client.puts(@destination, nil, { 'reply-to' => @destination })

    got_message = false
    client.subscribe(@destination) do |msg|
      got_message = true if msg.body == reply_to_body
      reply_to_body
    end
    let_background_processor_run
    assert got_message

    client.disconnect
  end

  it 'unsubscribes' do
    client = Klomp::Client.new(@uris).connect

    subscribe_frames = client.subscribe(@destination) { |msg| }
    unsub_frames = client.unsubscribe(subscribe_frames)
    assert_equal subscribe_frames.length, unsub_frames.length
    let_background_processor_run

    assert client.subscriptions.flatten.empty?, "expected connection to have no subscriptions"

    client.disconnect
  end

  it 'sends all unknown options through to OnStomp' do
    client = Klomp::Client.new(@uris.first, :haz_cheezburgers => true, :retry_attempts => 42).connect
    assert client.write_conn.connected?
    assert_equal 42, client.write_conn.retry_attempts
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

    client = Klomp::Client.new(@uris.first, :pool => pool_class)
    conn = client.write_conn
    def conn.sleep_for_retry(*) end # skip sleep between retries for test

    client.reconnect
    assert_equal 6, attempts
  end
end
