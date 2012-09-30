require 'socket'

class Loldance
  FRAME_SEP = "\x00"          # null character is frame separator
  class Connection

    attr_reader :options

    def initialize(server, options={})
      host, port = server.split ':'
      @options = options
      @options['server'] = [host, port.to_i]
      @options['host'] ||= host
      connect
    end

    def publish(queue, body, headers={})
      write Frames::Send.new(queue, body, headers)
    end

    private
    def connect
      @socket  = TCPSocket.new *options['server']
      @socket.set_encoding 'UTF-8'
      write Frames::Connect.new(options)
      read Frames::Connected, 0.1
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
  end
end
