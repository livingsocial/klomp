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

      if uri.is_a?(Array)
        @write_conn = OnStomp::Failover::Client.new(uri, ofc_options)
        @read_conn = uri.inject([]) { |memo,obj| memo + [OnStomp::Failover::Client.new([obj], ofc_options)] }
      else
        @write_conn = OnStomp::Failover::Client.new([uri], ofc_options)
        @read_conn = [@write_conn]
      end
    end

    def connect
      ([@write_conn] + @read_conn).uniq.each { |c| c.connect }
      self
    end

    def disconnect(headers={})
      ([@write_conn] + @read_conn).uniq.each { |c| c.disconnect(headers) }
    end

    def ack(*args)
      @read_conn.each { |c| c.ack(*args) }
    end

    def nack(*args)
      @read_conn.each { |c| c.nack(*args) }
    end

    def beat
      ([@write_conn] + @read_conn).uniq.each { |c| c.beat }
    end

    def send(destination, body=nil, headers={}, &block)
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

    def unsubscribe(frame_or_id, headers={})
      frame_or_id.each { |obj| @read_conn.each { |c| c.unsubscribe(obj, headers) } }
    end

  end

end
