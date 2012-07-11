require 'minitest/autorun'
require 'minitest/pride'

require 'klomp'
require File.expand_path('../test_helper', __FILE__)

describe Klomp::Client do

  include KlompTestHelpers

  before do
    @adapter = :stomp
    @uris = [
      'stomp://admin:password@localhost:61613',
      'stomp://admin:password@127.0.0.1:62613'
    ]
    @destination = '/queue/test_component.test_event'
  end

  it "unsubscribes" do
    client = Klomp::Client.new(@uris, :adapter => @adapter).connect
    client.subscribe(@destination) { |msg| }
    client.unsubscribe(@destination)
    client.disconnect
  end

end
