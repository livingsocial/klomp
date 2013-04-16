class Klomp
  class Subscription
    attr_reader :subscriber, :headers

    def initialize(subscriber, headers)
      @subscriber = subscriber
      @headers = headers
    end

    def call(message = nil)
      @subscriber.call(message)
    end
  end
end
