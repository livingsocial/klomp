class Loldance
  class FrameError < Error; end

  module Frames
    class Frame
      def name
        @name ||= self.class.name.split('::').last.upcase
      end

      def headers
        @headers ||= {}
      end

      def body
        @body ||= ""
      end

      def to_s
        "#{name}\n#{dump_headers}\n\n#{@body}#{FRAME_SEP}"
      end

      def dump_headers
        @headers.map do |pair|
          pair.map {|x| x.gsub("\n","\\n").gsub(":","\\c").gsub("\\", "\\\\") }.join(':')
        end.join("\n")
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
        [parse_headers(headers), body.chomp("\000")]
      end

      def parse_headers(data)
        frame = nil
        {}.tap do |headers|
          data.lines.each do |line|
            unless frame
              frame = line.chomp
              @error = frame == "ERROR"
              if !@error && frame != name
                raise Loldance::FrameError,
                  "unexpected frame #{frame} (expected #{name})"
              end
              next
            end
            kv = line.chomp.split(':').map {|x| x.gsub("\\n","\n").gsub("\\c",":").gsub("\\\\", "\\")}
            headers[kv.first] = kv.last
          end
        end
      end
    end

    class Connect < Frame
      def initialize(options)
        headers['accept-version'] = '1.1'
        headers['host'] = options['host'] if options['host']
        headers['login'] = options['login'] if options['login']
        headers['password'] = options['password'] if options['password']
      end
    end

    class Connected < ServerFrame
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
  end
end
