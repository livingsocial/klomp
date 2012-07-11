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

  [ :onstomp, :stomp ].each do |adapter|

    it "(#{adapter}) has a logger" do
      logger = Logger.new(STDOUT)
      client = Klomp::Client.new(@uris, :adapter => adapter, :logger => logger)
      assert_equal client.log, logger
    end

    it "(#{adapter}) sends all unknown options through to the underlying library" do
      client = Klomp::Client.new(@uris.first, :adapter => adapter, :haz_cheezburgers => true, :retry_attempts => 42).connect
      assert client.connected?.values.all?
      assert_equal 42, client.write_conn.retry_attempts if adapter == :onstomp
      client.disconnect
    end

    it "(#{adapter}) accepts a single uri and establishes separate failover connections for writes and reads" do
      client = Klomp::Client.new(@uris.first, :adapter => adapter).connect
      assert_equal [client.write_conn], client.read_conn
      assert client.connected?.values.all?
      client.disconnect
    end

    it "(#{adapter}) accepts an array of uris and establishes separate failover connections for writes and reads" do
      client = Klomp::Client.new(@uris, :adapter => adapter).connect
      assert client.all_conn.length == @uris.length + 1
      assert client.connected?.values.all?
      client.disconnect
    end

    it "(#{adapter}) disconnnects" do
      client = Klomp::Client.new(@uris.first, :adapter => adapter).connect
      assert client.connected?.values.all?
      client.disconnect
      refute client.connected?.values.any?
    end

    it "(#{adapter}) sends requests and gets responses" do
      client = Klomp::Client.new(@uris, :adapter => adapter).connect
      body  = { 'body' => rand(36**128).to_s(36) }

      client.send(@destination, body, :ack=>'client')
      got_message = false
      client.subscribe(@destination) do |msg|
        got_message = true if msg.body == body
        client.ack(msg)
      end
      let_background_processor_run
      client.disconnect

      assert got_message
    end

    it "(#{adapter}) automatically publishes responses to the reply-to destination" do
      client        = Klomp::Client.new(@uris, :adapter => adapter).connect
      reply_to_body = { 'reply_to_body' => rand(36**128).to_s(36) }

      client.send(@destination, nil, { 'reply-to' => @destination })

      got_message = false
      client.subscribe(@destination) do |msg|
        got_message = true if msg.body == reply_to_body
        reply_to_body
      end
      let_background_processor_run
      client.disconnect

      assert got_message
    end

    it "(#{adapter}) sends messages with uuids in the 'id' header" do
      client = Klomp::Client.new(@uris, :adapter => adapter, :translate_json => false).connect
      client.send(@destination, '')

      received_message = false
      client.subscribe(@destination) do |msg|
        received_message = msg
      end
      let_background_processor_run
      client.disconnect

      assert received_message
      assert received_message.headers['id'], "message did not have an id"
      assert received_message.headers['id'] =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
        "message id did not look like a uuid"
    end

    it "(#{adapter}) allows customization of the uuid generator" do
      generator = Object.new
      def generator.generate; "42"; end

      client = Klomp::Client.new(@uris, :adapter => adapter, :translate_json => false, :uuid => generator).connect
      client.send(@destination, '')

      received_message = false
      client.subscribe(@destination) do |msg|
        received_message = msg
      end
      let_background_processor_run
      client.disconnect

      assert received_message
      assert received_message.headers['id'], "message did not have an id"
      assert_equal "42", received_message.headers['id']
    end

    it "(#{adapter}) allows disabling generated message ids" do
      client = Klomp::Client.new(@uris, :adapter => adapter, :translate_json => false, :uuid => false).connect
      client.send(@destination, '')

      received_message = false
      client.subscribe(@destination) do |msg|
        received_message = msg
      end
      let_background_processor_run
      client.disconnect

      assert received_message
      refute received_message.headers['id'], "message had an id"
    end

    it "(#{adapter}) logs message ids" do
      logger = Object.new
      def logger.msgs; @msgs; end
      def logger.info(msg) (@msgs ||= []) << msg end

      client = Klomp::Client.new(@uris, :adapter => adapter, :translate_json => false, :logger => logger).connect
      client.send(@destination, '')

      received_message = false
      client.subscribe(@destination) do |msg|
        received_message = msg
      end
      let_background_processor_run
      client.disconnect

      assert received_message
      assert received_message.headers['id'], "message did not have an id"

      assert_equal 2, logger.msgs.length
      assert logger.msgs[0] =~ /\[Sending\] ID=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
      sent_id = $1
      assert logger.msgs[1] =~ /\[Received\] ID=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
      received_id = $1
      assert_equal sent_id, received_id
    end

  end

end
