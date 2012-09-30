require 'socket'

class Loldance
  FRAME_SEP = "\x00"          # null character is frame separator
  class Connection

    attr_reader :options

    def initialize(server, options={})
      host, port = server.split ':'
      @options = options
      @options['host'] ||= host
      @socket  = TCPSocket.new host, port.to_i
      @socket.set_encoding 'UTF-8'
      connect
    end

    private
    def connect
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
