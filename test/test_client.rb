require 'minitest/autorun'
require 'minitest/pride'

require 'klomp'

describe Klomp::Client do

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

  it 'disconnnects' do
    client = Klomp::Client.new(@uris.first).connect
    assert client.write_conn.connected?
    client.disconnect
    refute client.write_conn.connected?
  end

  it 'sends heartbeat' do
    client = Klomp::Client.new(@uris).connect.beat
  end

  it 'sends requests and gets responses' do
    client = Klomp::Client.new(@uris).connect
    body  = { 'random_string' => rand(36**128).to_s(36) }

    client.send(@destination, body) do |r|
      assert_kind_of OnStomp::Components::Frame, r
    end

    got_message = false
    client.subscribe(@destination) do |msg|
      got_message = true if msg.body == body
    end
    sleep 1
    assert got_message

    client.disconnect
  end

  it 'automatically publishes responses to the reply-to destination' do
    client        = Klomp::Client.new(@uris).connect
    reply_to_body = { 'random_string' => rand(36**128).to_s(36) }

    client.send(@destination, nil, { 'reply-to' => @destination })

    got_message = false
    client.subscribe(@destination) do |msg|
      got_message = true if msg.body == reply_to_body
      reply_to_body
    end
    sleep 1
    assert got_message

    client.disconnect
  end

  it 'unsubscribes' do
    client = Klomp::Client.new(@uris).connect

    subscribe_frames = client.subscribe(@destination) { |msg| }
    client.unsubscribe(subscribe_frames)

    client.disconnect
  end

end
