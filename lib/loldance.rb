class Loldance
  VERSION = '0.0.1'

  class Error < StandardError; end

  attr_reader :connections, :subscriptions

  def initialize(servers)
    raise ArgumentError, "no servers given" if servers.empty?
    @connections = servers.map {|s| Connection.new(s) }
    @subscriptions = {}
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
    raise Loldance::Error, "no subscriber provided" unless subscriber || block
    raise Loldance::Error, "subscriber does not respond to #call" if subscriber && !subscriber.respond_to?(:call)
    subscriptions[queue] = subscriber || block
    connections.each {|conn| conn.subscribe(queue, subscriber, &block) }
  end

  def unsubscribe(queue)
    connections.each {|conn| conn.unsubscribe(queue) rescue nil }
    subscriptions.delete(queue)
  end
end

require 'loldance/connection'
