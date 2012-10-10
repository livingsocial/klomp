class Klomp
  class FrameError < Error; end

  module Frames
    class Frame
      def name; @name ||= self.class.name.split('::').last.upcase; end

      def headers;         @headers ||= {};       end
      def [](key);          headers[key];         end
      def []=(key, value);  headers[key] = value; end

      def body; @body ||= ""; end
      def body=(b); @body = b; end

      def to_s
        "#{name}\n#{dump_headers}\n#{@body}#{FRAME_SEP}"
      end

      def dump_headers
        headers.map do |pair|
          pair.map {|x| x.to_s.gsub("\n","\\n").gsub(":","\\c").gsub("\\", "\\\\") }.join(':')
        end.join("\n").tap {|s| s << "\n" unless s.empty? }
      end
    end

    class ServerFrame < Frame
      def initialize(data)
        @headers, @body = parse(data)
      end

      def error?
        @error
      end

      private
      def parse(data)
        headers, body = data.split("\n\n")
        [parse_headers(headers), body.chomp(FRAME_SEP)]
      end

      def parse_headers(data)
        frame = nil
        {}.tap do |headers|
          data.lines.each do |line|
            next if line == "\n"
            unless frame
              frame = line.chomp
              @error = frame == "ERROR"
              if !@error && frame != name
                raise Klomp::FrameError,
                  "unexpected frame #{frame} (expected #{name}):\n#{data}"
              end
              next
            end
            kv = line.chomp.split(':').map {|x| x.gsub("\\n","\n").gsub("\\c",":").gsub("\\\\", "\\") }
            headers[kv.first] = kv.last
          end
        end
      end
    end

    class Connect < Frame
      def initialize(options)
        headers['accept-version'] = '1.1'
        headers['host'] = options['host'] if options['host']
        headers['heart-beat'] = "0,0"
        headers['login'] = options['login'] if options['login']
        headers['passcode'] = options['passcode'] if options['passcode']
      end
    end

    class Connected < ServerFrame
    end

    class Message < ServerFrame
    end

    class Send < Frame
      def initialize(queue, body, hdrs)
        headers['destination'] = queue
        headers.update(hdrs.reject{|k,v| %w(destination content-length).include? k })
        headers['content-type'] ||= 'text/plain'
        headers['content-length'] = body.bytesize.to_s
        @body = body
      end
    end

    class Subscribe < Frame
      attr_accessor :previous_subscriber
      def initialize(queue)
        headers['id'] = queue
        headers['destination'] = queue
        headers['ack'] = 'auto'
      end
    end

    class Unsubscribe < Frame
      def initialize(queue)
        headers['id'] = queue
      end
    end

    class Disconnect < Frame
    end
  end
end
