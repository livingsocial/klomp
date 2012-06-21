require 'onstomp'
require 'onstomp/failover'
require 'json'
require 'logger'

module Klomp

  class Client
    attr_reader :read_conn, :write_conn
    attr_accessor :last_connect_exception

    def initialize(uri, options={})
      @translate_json = options.fetch(:translate_json, true)
      @auto_reply_to  = options.fetch(:auto_reply_to, true)
      @logger         = options.fetch(:logger, nil)

      # defaults for retry delay and attempts
      options[:retry_delay]    ||= 2
      options[:retry_attempts] ||= 10

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

    def connect
      @all_conn.each do |conn|
        begin
          attempts = conn.retry_attempts
          conn.retry_attempts = 1
          conn.connect
        rescue OnStomp::Failover::MaximumRetriesExceededError
          location = conn.active_client.uri.dup.tap {|u| u.password = 'REDACTED' }.to_s
          msg = ": #{last_connect_exception.message}" if last_connect_exception
          raise OnStomp::ConnectFailedError, "initial connection failed for #{location}#{msg}"
        ensure
          conn.retry_attempts = attempts
        end
      end
      self
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

    def unsubscribe(frames, headers={})
      if !frames.respond_to?(:length) || frames.length != @read_conn.length
        raise ArgumentError,
          "frames is not an array or its length does not match number of connections"
      end
      frames.each_with_index.map {|f,i| @read_conn[i].unsubscribe f, headers }
    end

    def subscriptions
      @read_conn.map {|c| c.active_client.subscriptions }
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
    ]

    def method_missing(method, *args, &block)
      case method
      when *WRITE_ONLY_METHODS
        @write_conn.__send__(method, *args, &block)
      when *READ_ONLY_METHODS
        @read_conn.map {|c| c.__send__(method, *args, &block) }
      else
        @all_conn.map {|c| c.__send__(method, *args) }
      end
    end

    private
    def configure_connections
      klomp_client = self
      @all_conn.each do |c|
        c.on_failover_connect_failure do
          klomp_client.last_connect_exception = $!
        end
      end
    end
  end

end
