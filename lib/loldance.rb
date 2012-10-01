class Loldance
  VERSION = '0.0.1'

  class Error < StandardError; end

  attr_reader :connections

  def initialize(servers)
    raise ArgumentError, "no servers given" if servers.empty?
    @connections = servers.map {|s| Connection.new(s) }
  end

  def publish(queue, body, headers = {})
    connections_remaining = connections.dup
    begin
      conn = connections_remaining.sample
      conn.publish(queue, body, headers)
    rescue
      connections_remaining.delete conn
      retry unless connections_remaining.empty?
      raise
    end
  end

  def subscribe(queue, subscriber = nil, &block)
    connections.each {|conn| conn.subscribe(queue, subscriber, &block) }
  end

  def unsubscribe(queue)
    connections.each {|conn| conn.unsubscribe(queue) rescue nil }
  end
end

require 'loldance/connection'
require 'loldance/frames'
