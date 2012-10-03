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
      write Frames::Subscribe.new(queue) unless previous
      start_subscriber_thread
      previous
    end

    def unsubscribe(queue)
      write Frames::Unsubscribe.new(queue) if subscriptions.delete queue
    end

    def connected?()    @socket end
    def closed?()       @closing && @socket.nil? end

    def disconnect
      close!
      stop_subscriber_thread
      write Frames::Disconnect.new rescue nil
      @socket.close rescue nil
      @socket = nil
    end

    def reconnect
      return if connected?
      logger.warn "reconnect server=#{options['server'].join(':')}" if logger
      connect
      subs = subscriptions.dup
      subscriptions.clear
      subs.each {|queue, subscriber| subscribe(queue, subscriber) }
    end

    private
    def connect
      @socket  = TCPSocket.new *options['server']
      @socket.set_encoding 'UTF-8'
      write Frames::Connect.new(options)
      frame = read Frames::Connected, 0.1
      log_frame frame if logger
      raise Error, frame.headers['message'] if frame.error?
    end

    def write(frame)
      raise Error, "connection closed" if closed?
      raise Error, "disconnected"      unless connected?

      rs, ws, = IO.select(nil, [@socket], nil, 0.1)
      raise Error, "connection unavailable for write" unless ws && !ws.empty?

      @socket.write frame.to_s
      log_frame frame if logger
    rescue Error
      raise
    rescue
      trash_socket_and_launch_sentinel
      raise
    end

    def read(type, timeout = nil)
      rs, = IO.select([@socket], nil, nil, timeout)
      raise Error, "connection unavailable for read" unless rs && !rs.empty?
      type.new @socket.gets(FRAME_SEP)
    rescue Error
      raise
    rescue
      trash_socket_and_launch_sentinel
      raise
    end

    def log_frame(frame)
      return unless logger.debug?
      body = frame.body
      body = body.lines.first.chomp + '...' if body =~ /\n/
      logger.debug "frame=#{frame.name} #{frame.headers.map{|k,v| k + '=' + v }.join(' ')} body=#{body}"
    end

    def log_exception(ex, level = :error)
      logger.send level, "exception=#{ex.class.name} message=#{ex.message.inspect} backtrace[0]=#{ex.backtrace[0]} backtrace[1]=#{ex.backtrace[1]}"
      logger.debug "exception=#{ex.class.name} full_backtrace=" + ex.backtrace.join("\n")
    end

    def close!
      @closing = true
    end

    def trash_socket_and_launch_sentinel
      @socket.close rescue nil
      @socket = nil
      Sentinel.new(self)
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
