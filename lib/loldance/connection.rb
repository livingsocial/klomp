require 'socket'

class Loldance
  FRAME_SEP = "\x00"          # null character is frame separator
  class Connection

    attr_reader :options, :subscriptions

    def initialize(server, options={})
      host, port = server.split ':'
      @options = options
      @options['server'] = [host, port.to_i]
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

    def connected?
      @socket && !@closed
    end

    def disconnect
      @closed = true
      stop_subscriber_thread
      write Frames::Disconnect.new
      @socket.close rescue nil
      @socket = nil
    end

    private
    def connect
      @socket  = TCPSocket.new *options['server']
      @socket.set_encoding 'UTF-8'
      write Frames::Connect.new(options)
      frame = read Frames::Connected, 0.1
      raise Loldance::Error, frame.headers['message'] if frame.error?
    end

    def write(frame)
      rs, ws, = IO.select(nil, [@socket], nil, 0.1)
      raise Error, "connection unavailable for write" unless ws && !ws.empty?
      @socket.write frame.to_s
    end

    def read(type, timeout = nil)
      rs, = IO.select([@socket], nil, nil, timeout)
      raise Error, "connection unavailable for read" unless rs && !rs.empty?
      type.new @socket.gets(FRAME_SEP)
    end

    DISCONNECT = Class.new(StandardError)

    def start_subscriber_thread
      @subscriber_thread ||= Thread.new do
        loop do
          begin
            message = read Frames::Message
            if subscriber = subscriptions[message.headers['destination']]
              subscriber.call message
            end
          rescue DISCONNECT
            break
          rescue => e
            $stderr.puts e.to_s, *e.backtrace
            # don't die if an exception occurs, just check if we've been closed
            # TODO: log exception
          end
          break if @closed
        end
      end
    end

    def stop_subscriber_thread
      @subscriber_thread.raise DISCONNECT, "disconnect" if @subscriber_thread
      @subscriber_thread = nil
    end
  end
end
