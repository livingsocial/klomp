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
      vhosts = apollo_api_get_json "/broker/virtual-hosts.json"
      vhost = vhosts['rows'].detect {|row| row['queues'].include?('greeting') }['id']
      @queue_path = "/broker/virtual-hosts/#{vhost}/queues/greeting.json"
      queue = apollo_api_get_json @queue_path
      queue['metrics']['queue_items'].to_i.should > 0
    end

    after do
      apollo_api_delete @queue_path
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

  def apollo_mgmt_url(path)
    "http://localhost:61680#{path}"
  end

  def apollo_api_get_json(path)
    open(apollo_mgmt_url(path), :http_basic_authentication => credentials) {|f| JSON::parse(f.read) }
  end

  def apollo_api_delete(path)
    `curl -s -f -X DELETE -u #{credentials.join(':').inspect} #{apollo_mgmt_url path}`
    $?.should be_success
  end
end
