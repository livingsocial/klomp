require 'onstomp'
require 'onstomp/failover'
require 'json'
require 'logger'

module Klomp

  class Client
    attr_reader :options, :read_conn, :write_conn

    def initialize(uri, options={})
      @options = {
        :translate_json => true,
        :auto_reply_to  => true,
        :logger         => false
      }.merge(options || {})

      ofc_options = @options.inject({
        :retry_attempts => -1,
        :retry_delay    => 1
      }) { |memo,(k,v)| memo.has_key?(k) ? memo.merge({k => v}) : memo }

      if uri.is_a?(Array)
        @write_conn = OnStomp::Failover::Client.new(uri, ofc_options)
        @read_conn = uri.inject([]) { |memo,obj| memo + [OnStomp::Failover::Client.new([obj], ofc_options)] }
      else
        @write_conn = OnStomp::Failover::Client.new([uri], ofc_options)
        @read_conn = [@write_conn]
      end
    end

    def send(*args, &block)
      if @options[:translate_json] && [Array, Hash].any? { |type| args[1].kind_of?(type) }
        args[1] = args[1].to_json
        args[2] = {} if args[2].nil?
        args[2][:'content-type'] = 'application/json'
      else
        args[1] = args[1].to_s
      end
      log.info("[Sending] Destination=#{args[0]} Body=#{args[1]} Headers=#{args[2]}") if log
      @write_conn.send(*args, &block)
    end
    alias :puts :send

    def subscribe(*args, &block)
      frames = []
      @read_conn.each do |c|
        frames << c.subscribe(*args) do |msg|
          log.info("[Received] Body=#{msg.body} Headers=#{msg.headers.to_hash.sort}") if log
          if @options[:translate_json]
            msg.body = begin
              JSON.parse(msg.body)
            rescue JSON::ParserError
              msg.body
            end
          end
          reply_args = yield msg
          if @options[:auto_reply_to] && !msg.headers[:'reply-to'].nil?
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
      @options[:logger]
    end

    def method_missing(method, *args, &block)
      write_only_methods = [
        :abort,
        :begin,
        :commit,
      ]
      read_only_methods = [
        :ack,
        :nack,
        :unsubscribe
      ]
      returns = {
        :connect => self
      }

      result = if write_only_methods.include?(method)
        @write_conn.send(method, *args, &block)
      elsif read_only_methods.include?(method)
        @read_conn.map { |c| c.__send__(method, *args, &block) }
      else
        ([@write_conn] + @read_conn).uniq.map { |c| c.__send__(method, *args) }
      end
      returns.include?(method) ? returns[method] : result
    end

  end

end
