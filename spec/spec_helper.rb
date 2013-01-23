require 'simplecov' if RUBY_VERSION >= '1.9'
require 'klomp'
require 'rspec'
require 'rspec-given'
require 'active_support'

Dir[File.expand_path('../support/', __FILE__) + '/*.rb'].each {|f| require f }

module Frames
  def frame(type)
    File.read(File.expand_path("../frames/#{type}.txt", __FILE__))
  end
end

def queue_available?
  s = TCPSocket.new 'localhost', 61613
  true
rescue
  false
ensure
  s && s.close
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.filter_run_excluding :acceptance  unless queue_available?
  if ENV['PERF']
    config.filter_run :performance
  else
    config.filter_run_excluding :performance
  end

  config.before :each do
    Klomp::Frames::Frame.any_instance.stub(:new_headers) do
      ActiveSupport::OrderedHash.new
    end
  end

  config.include Frames
end
