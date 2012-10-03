class Klomp
  class Sentinel
    def initialize(connection)
      @connection = connection
      Thread.new { run } unless @connection.connected?
    end

    def run
      fib_state = [0, 1]
      loop do
        begin
          @connection.reconnect
          break
        rescue
          sleep fib_state[1]
          fib_state = [fib_state[1], fib_state[0]+fib_state[1]]
        end
      end
    end
  end
end
