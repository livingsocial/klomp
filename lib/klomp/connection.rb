require 'socket'
require 'uri'

class Klomp
  FRAME_SEP = "\x00"          # null character is frame separator
  class Connection

    attr_reader :options, :subscriptions, :logger

    def initialize(server, options={})
      @options = options

      if server =~ /^stomp:\/\//
        uri                  = URI.parse server
        host, port           = uri.host, uri.port
        @options['login']    = uri.user if uri.user
        @options['passcode'] = uri.password if uri.password
        if uri.query && !uri.query.empty?
          uri.query.split('&').each {|pair| k, v = pair.split('=', 2); @options[k] = v }
        end
      else
        address            = server.split ':'
        port, host         = address.pop.to_i, address.pop
        @options['host'] ||= address.pop unless address.empty?
      end

      @options['server']   = [host, port]
      @options['host']   ||= host
      @subscriptions = {}
      @logger = options['logger']
      @select_timeout = options['select_timeout'] || 0.1
      connect
    end

    def publish(queue, body, headers={})
      write Frames::Send.new(queue, body, headers)
    end

    def subscribe(queue, subscriber = nil, &block)
      raise Klomp::Error, "no subscriber provided" unless subscriber || block
      raise Klomp::Error, "subscriber does not respond to #call" if subscriber && !subscriber.respond_to?(:call)
      previous = subscriptions[queue]
      subscriptions[queue] = subscriber || block
      frame = Frames::Subscribe.new(queue)
      if previous
        frame.previous_subscriber = previous
      else
        write frame
      end
      start_subscriber_thread
      frame
    end

    def unsubscribe(queue)
      queue = queue.headers['destination'] if Frames::Subscribe === queue
      write Frames::Unsubscribe.new(queue) if subscriptions.delete queue
    end

    def connected?()    @socket end
    def closed?()       @closing && @socket.nil? end

    def disconnect
      close!
      stop_subscriber_thread
      frame = Frames::Disconnect.new
      write frame rescue nil
      @socket.close rescue nil
      @socket = nil
      frame
    end

    def reconnect
      return if connected?
      logger.warn "reconnect server=#{options['server'].join(':')}" if logger
      connect
      subs = subscriptions.dup
      subscriptions.clear
      subs.each {|queue, subscriber| subscribe(queue, subscriber) }
      @sentinel = nil
    end

    private
    def connect
      @socket  = TCPSocket.new *options['server']
      @socket.set_encoding 'UTF-8'
      write Frames::Connect.new(options)
      frame = read Frames::Connected, @select_timeout
      log_frame frame if logger
      raise Error, frame.headers['message'] if frame.error?
    end

    def write(frame)
      raise Error, "connection closed" if closed?
      raise Error, "disconnected"      unless connected?

      rs, ws, = IO.select(nil, [@socket], nil, @select_timeout)
      raise Error, "connection unavailable for write" unless ws && !ws.empty?

      @socket.write frame.to_s
      log_frame frame if logger
      frame
    rescue Error
      raise
    rescue => e
      go_offline e
      raise
    end

    def read(type, timeout = nil)
      rs, = IO.select([@socket], nil, nil, timeout)
      raise Error, "connection unavailable for read" unless rs && !rs.empty?
      type.new(@socket.gets(FRAME_SEP)).tap {|frame| log_frame frame if logger }
    rescue Error
      raise
    rescue => e
      go_offline e
      raise
    end

    def log_frame(frame)
      return unless logger.debug?
      body = frame.body
      body = body.lines.first.chomp + '...' if body =~ /\n/
      logger.debug "frame=#{frame.name} #{frame.headers.map{|k,v| k.to_s + '=' + v.to_s.inspect }.join(' ')} body=#{body}"
    end

    def log_exception(ex, level = :error, msg_start = '')
      logger.send level, "#{msg_start}exception=#{ex.class.name} message=#{ex.message.inspect} backtrace[0]=#{ex.backtrace[0]} backtrace[1]=#{ex.backtrace[1]}"
      logger.debug "exception=#{ex.class.name} full_backtrace=" + ex.backtrace.join("\n")
    end

    def close!
      @closing = true
    end

    def go_offline(ex)
      log_exception(ex, :warn, "offline server=#{options['server'].join(':')} ") if logger
      return if @sentinel && @sentinel.alive?
      @socket.close rescue nil
      @socket = nil
      @sentinel = Sentinel.new(self)
      stop_subscriber_thread
    end

    INTERRUPT = Class.new(Error)

    def start_subscriber_thread
      @subscriber_thread ||= Thread.new do
        loop do
          begin
            message = read Frames::Message
            raise Error, message.headers['message'] if message.error?
            if subscriber = subscriptions[message.headers['destination']]
              subscriber.call message
            end
          rescue INTERRUPT
            break
          rescue => e
            log_exception(e, :warn) if logger
          end
          break if @closing
        end
      end
    end

    def stop_subscriber_thread
      thread, @subscriber_thread = @subscriber_thread, nil
      thread.raise INTERRUPT, "disconnect" if thread
    end
  end
end
