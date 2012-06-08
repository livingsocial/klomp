module Klomp

  class Client
    attr_reader :options, :read_conn, :write_conn

    def initialize(uri, options={})
      @options ||= {
        :translate_json => true,
        :auto_reply_to  => true
      }

      ofc_options = options.inject({
        :retry_attempts => -1,
        :retry_delay    => 1
      }) { |memo,(k,v)| memo.merge({k => v}) if memo.has_key?(k) }

      if uri.respond_to?(:each)
        @write_conn = OnStomp::Failover::Client.new(uri, ofc_options)
        @read_conn = uri.inject([]) { |memo,obj| memo + [OnStomp::Failover::Client.new([obj], ofc_options)] }
      else
        @write_conn = OnStomp::Failover::Client.new([uri], ofc_options)
        @read_conn = [@write_conn]
      end
    end

    def connect
      @write_conn.connect
      @read_conn.each { |c| c.connect }
      self
    end

    def disconnect
      @write_conn.disconnect if @write_conn.connected?
      @read_conn.select { |c| c.connected? }.each { |c| c.disconnect }
    end

    def send(destination, body=nil, headers={}, &block)
      headers ||= {}
      if @options[:translate_json] && [Array, Hash].any? { |type| body.kind_of?(type) }
        body = body.to_json
        headers[:'content-type'] = 'application/json'
      else
        body = body.to_s
      end
      receipt = @write_conn.puts(destination, body, headers)
      yield receipt if block_given?
    end

    def subscribe(destination, headers={}, &block)
      headers ||= {}
      frames = []
      @read_conn.each do |c|
        frames << c.subscribe(destination, headers) do |msg|
          if @options[:translate_json]
            msg.body = begin
              JSON.parse(msg.body)
            rescue JSON::ParserError
              msg.body
            end
          end
          reply_body, reply_headers = yield msg
          if @options[:auto_reply_to] && !msg.headers[:'reply-to'].nil?
            send(msg.headers[:'reply-to'], reply_body, reply_headers)
          end
        end
      end
      frames
    end

    def unsubscribe(frame_or_id, headers={})
      headers ||= {}
      frame_or_id.each { |obj| @read_conn.each { |c| c.unsubscribe(obj, headers) } }
    end

  end

end
