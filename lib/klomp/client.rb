require 'onstomp'
require 'onstomp/failover'
require 'json'
require 'logger'

module Klomp

  class Client
    attr_reader :read_conn, :write_conn

    def initialize(uri, options=nil)
      options ||= {}
      @translate_json, @auto_reply_to = true, true # defaults
      @translate_json = options.delete(:translate_json) if options.has_key?(:translate_json)
      @auto_reply_to  = options.delete(:auto_reply_to)  if options.has_key?(:auto_reply_to)
      @logger         = options.delete(:logger)

      if uri.is_a?(Array)
        @write_conn = OnStomp::Failover::Client.new(uri, options)
        @read_conn = uri.map {|obj| OnStomp::Failover::Client.new([obj], options) }
      else
        @write_conn = OnStomp::Failover::Client.new([uri], options)
        @read_conn = [@write_conn]
      end
      @all_conn = ([@write_conn] + @read_conn).uniq
      configure_connections
    end

    def send(*args, &block)
      if @translate_json && args[1].respond_to?(:to_json)
        args[1] = args[1].to_json
        args[2] ||= {}
        args[2][:'content-type'] = 'application/json'
      else
        args[1] = args[1].to_s
      end
      log.info("[Sending] Destination=#{args[0]} Body=#{args[1]} Headers=#{args[2]}") if log
      @write_conn.send(*args, &block)
    end
    alias puts send
    alias publish send

    def subscribe(*args, &block)
      frames = []
      @read_conn.each do |c|
        frames << c.subscribe(*args) do |msg|
          log.info("[Received] Body=#{msg.body} Headers=#{msg.headers.to_hash.sort}") if log
          if @translate_json
            msg.body = begin
              JSON.parse(msg.body)
            rescue JSON::ParserError
              msg.body
            end
          end
          reply_args = yield msg
          if @auto_reply_to && !msg.headers[:'reply-to'].nil?
            if reply_args.is_a?(Array)
              send(msg.headers[:'reply-to'], *reply_args)
            else
              send(msg.headers[:'reply-to'], reply_args)
            end
          end
        end
      end
      frames
    end

    def log
      @logger
    end

    WRITE_ONLY_METHODS = [
      :abort,
      :begin,
      :commit,
    ]

    READ_ONLY_METHODS = [
      :ack,
      :nack,
      :unsubscribe,
    ]

    def method_missing(method, *args, &block)
      case method
      when *WRITE_ONLY_METHODS
        @write_conn.send(method, *args, &block)
      when *READ_ONLY_METHODS
        @read_conn.map {|c| c.__send__(method, *args, &block) }
      when :connect
        @all_conn.each {|c| c.connect}
        self
      else
        @all_conn.map {|c| c.__send__(method, *args) }
      end
    end

    private
    def configure_connections
      @all_conn.each do |c|
        c.on_failover_connect_failure do
          raise if OnStomp::FatalConnectionError === $!
        end
      end
    end
  end

end
