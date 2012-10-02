require 'socket'

class Loldance
  FRAME_SEP = "\x00"          # null character is frame separator
  class Connection

    attr_reader :options, :subscriptions

    def initialize(server, options={})
      address = server.split ':'
      port, host = address.pop.to_i, address.pop
      @options = options
      @options['server'] = [host, port.to_i]
      @options['host'] ||= address.pop unless address.empty?
      @options['host'] ||= host
      @subscriptions = {}
      connect
    end

    def publish(queue, body, headers={})
      write Frames::Send.new(queue, body, headers)
    end

    def subscribe(queue, subscriber = nil, &block)
      raise Loldance::Error, "no subscriber provided" unless subscriber || block
      raise Loldance::Error, "subscriber does not respond to #call" if subscriber && !subscriber.respond_to?(:call)
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
      raise Error, frame.headers['message'] if frame.error?
    end

    def write(frame)
      raise Error, "connection closed" if closed?
      raise Error, "disconnected"      unless connected?

      rs, ws, = IO.select(nil, [@socket], nil, 0.1)
      raise Error, "connection unavailable for write" unless ws && !ws.empty?

      @socket.write frame.to_s
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
            $stderr.puts e.to_s, *e.backtrace if $debug
            # don't die if an exception occurs, just check if we've been closed
            # TODO: log exception
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
