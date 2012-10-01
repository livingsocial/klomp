# Like rspec-spies, but better.
#
# Leverages RSpec's builtin MessageExpectation class/DSL so that you can use arg
# matchers, # of invocation matchers, etc.

require 'rspec/mocks'

class RSpec::Mocks::Proxy
  attr_reader :messages_received, :error_generator

  # This does the equivalent of rspec-spies monkey patch, but with less work
  alias orig_message_received message_received
  def message_received(*args, &block)
    record_message_received(*args, &block)
    orig_message_received(*args, &block)
  end

  # Be sure to reset the messages received between specs!
  alias orig_reset reset
  def reset
    orig_reset.tap { messages_received.clear }
  end
end

module RSpec::Mocks::Methods

  def messages_received
    __mock_proxy.messages_received
  end

  def error_generator
    __mock_proxy.error_generator
  end

  def replay_on(other, &match_block)
    messages_received.each do |msg, args, &block|
      if !match_block || match_block.call(msg,args,&block)
        other.send msg, *args, &block
      end
    end
  end

  def reset
    __mock_proxy.reset
  end
end

class RSpec::Mocks::MessageExpectation
  public :error_generator=
end

module RSpec::Matchers::HaveReceived
  class Matcher
    def initialize(message, expected_from)
      @message, @mock = message, RSpec::Mocks::Mock.new
      @mock.stub!(message)
      @expectation = @mock.should_receive(message, expected_from: expected_from)
    end

    def matches?(actual)
      begin
        @expectation.error_generator = actual.error_generator
        actual.replay_on(@mock) {|msg,args,&block| @message == msg }
        @mock.rspec_verify
        true
      rescue RSpec::Mocks::MockExpectationError => e
        @exception = e
        false
      end
    end

    def description
      "have received #{@message.inspect}"
    end

    def failure_message_for_should
      @exception.message
    end

    def failure_message_for_should_not
      begin
        @expectation.generate_error
      rescue RSpec::Mocks::MockExpectationError => e
        e.message.sub(/expected.*/m, "unexpected match")
      end
    end

    def method_missing(meth, *args, &block)
      @expectation.send meth, *args, &block
      self
    end
  end

  def have_received(message)
    Matcher.new(message, caller(1)[0])
  end
end

RSpec.configure do |config|
  config.include RSpec::Matchers::HaveReceived
end
