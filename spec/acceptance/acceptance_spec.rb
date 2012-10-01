require 'spec_helper'
require 'json'
require 'open-uri'

describe "Loldance acceptance", :acceptance => true do

  Given(:server) { "127.0.0.1:61613" }
  Given(:credentials) { %w(admin password) }
  Given(:options) { Hash[*%w(login passcode).zip(credentials).flatten] }
  Given(:clients) { [] }
  Given(:loldance) { Loldance.new(server, options).tap {|l| clients << l } }

  context "connect" do

    When { loldance }

    Then { loldance.should be_connected }

  end

  context "publish" do

    When { loldance.publish "/queue/greeting", "hello" }

    Then do
      vhosts = apollo_api_get("/broker/virtual-hosts.json")
      @vhost = vhosts['rows'].detect {|row| row['queues'].include?('greeting') }['id']
      queue = apollo_api_get("/broker/virtual-hosts/#{@vhost}/queues/greeting.json")
      queue['metrics']['queue_items'].to_i.should > 0
    end

    after do
      `curl -s -X DELETE -u #{credentials.join(':')} http://localhost:61680/broker/virtual-hosts/#{@vhost}/queues/greeting.json`
    end
  end

  context "subscribe" do

    Given(:subscriber) { double("subscriber") }
    Given { loldance.publish "/queue/greeting", "hello subscriber!" }

    When do
      subscriber.stub!(:call).and_return {|msg| subscriber.stub!(:message => msg) }
      loldance.subscribe "/queue/greeting", subscriber
    end

    Then do
      sleep 1
      subscriber.should have_received(:call).with(an_instance_of(Loldance::Frames::Message))
      subscriber.message.body.should == "hello subscriber!"
    end

  end

  after { clients.each(&:disconnect) }

  def apollo_api_get(path)
    open("http://localhost:61680#{path}",
         :http_basic_authentication => credentials) {|f| JSON::parse(f.read) }
  end
end
