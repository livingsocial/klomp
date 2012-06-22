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
    client = Klomp::Client.new(@uris, :logger=>logger)
    assert_equal client.log, logger
  end

  it 'sends heartbeat' do
    client = Klomp::Client.new(@uris).connect
    client.beat
    client.disconnect
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

    client.send(@destination, nil, { 'reply-to' => @destination })

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
    client.disconnect
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

  it 'sends messages with uuids in the :id header' do
    client = Klomp::Client.new(@uris, :translate_json => false).connect
    client.send(@destination, '')

    received_message = false
    client.subscribe(@destination) do |msg|
      received_message = msg
    end
    let_background_processor_run
    assert received_message
    assert received_message[:id], "message did not have an id"
    assert received_message[:id] =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
      "message id did not look like a uuid"

    client.disconnect
  end

  it 'allows customization of the uuid generator' do
    generator = Object.new
    def generator.generate; "42"; end

    client = Klomp::Client.new(@uris, :translate_json => false, :uuid => generator).connect
    client.send(@destination, '')

    received_message = false
    client.subscribe(@destination) do |msg|
      received_message = msg
    end
    let_background_processor_run
    assert received_message
    assert received_message[:id], "message did not have an id"
    assert_equal "42", received_message[:id]

    client.disconnect
  end

  it 'allows disabling generated message ids' do
    client = Klomp::Client.new(@uris, :translate_json => false, :uuid => false).connect
    client.send(@destination, '')

    received_message = false
    client.subscribe(@destination) do |msg|
      received_message = msg
    end
    let_background_processor_run
    assert received_message
    refute received_message[:id], "message had an id"

    client.disconnect
  end

  it 'logs message ids' do
    logger = Object.new
    def logger.msgs; @msgs; end
    def logger.info(msg) (@msgs ||= []) << msg end

    client = Klomp::Client.new(@uris, :translate_json => false, :logger => logger).connect
    client.send(@destination, '')

    received_message = false
    client.subscribe(@destination) do |msg|
      received_message = msg
    end
    let_background_processor_run
    assert received_message
    assert received_message[:id], "message did not have an id"

    assert_equal 2, logger.msgs.length
    assert logger.msgs[0] =~ /\[Sending\] ID=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
    sent_id = $1
    assert logger.msgs[1] =~ /\[Received\] ID=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
    received_id = $1
    assert_equal sent_id, received_id

    client.disconnect
  end
end
