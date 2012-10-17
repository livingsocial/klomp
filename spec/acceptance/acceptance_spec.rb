require 'spec_helper'
require 'json'
require 'open-uri'

describe "Klomp acceptance", :acceptance => true do

  include_context :acceptance_client

  context "connect" do

    When { klomp }

    Then { klomp.should be_connected }

  end

  context "publish" do

    When { klomp.publish "/queue/greeting", "hello" }

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
    Given { klomp.publish "/queue/greeting", "hello subscriber!" }

    When do
      subscriber.stub!(:call).and_return {|msg| subscriber.stub!(:message => msg) }
      klomp.subscribe "/queue/greeting", subscriber
      sleep 1         # HAX: waiting for message to be pushed back and processed
    end

    Then do
      subscriber.should have_received(:call).with(an_instance_of(Klomp::Frames::Message))
      subscriber.message.body.should == "hello subscriber!"
    end

    context "and unsubscribe" do

      When do
        subscriber.reset
        klomp.unsubscribe "/queue/greeting"
        klomp.publish "/queue/greeting", "hello subscriber?"
        sleep 1
      end

      Then do
        subscriber.should_not have_received(:call)
      end

    end

  end

  context "throughput test", :performance => true do

    require 'benchmark'

    Given(:num_threads) { (ENV['THREADS'] || 4).to_i }
    Given(:msgs_per_thread) { (ENV['MSGS'] || 10000).to_i }
    Given(:total) { num_threads * msgs_per_thread }

    Given do
      trap("QUIT") do
        Thread.list.each do |t|
          $stderr.puts
          $stderr.puts t.inspect
          $stderr.puts t.backtrace.join("\n  ")
        end
      end
    end

    Given { klomp }

    Then do
      Thread.abort_on_exception = true

      roundtrip_time = Benchmark.realtime do

        Thread.new do
          publish_time = Benchmark.realtime do
            threads = []
            1.upto(num_threads) do |i|
              threads << Thread.new do
                1.upto(msgs_per_thread) do |j|
                  id = i * j
                  print "." if id % 100 == 0
                  klomp.publish "/queue/greeting", "hello #{id}!", "id" => "greeting-#{id}"
                end
              end
            end
            threads.each(&:join)
          end

          puts "\n--------------------------------------------------------------------------------\n" \
          "Sending   #{total} messages took #{publish_time} using #{num_threads} threads\n" \
          "--------------------------------------------------------------------------------\n"
        end

        ids = []
        subscribe_time = Benchmark.realtime do
          klomp.subscribe "/queue/greeting" do |msg|
            id = msg.headers['id'][/(\d+)/, 1].to_i
            print "," if id % 100 == 0
            ids << id
          end

          Thread.pass until ids.length == total
        end

        puts "\n--------------------------------------------------------------------------------\n" \
        "Receiving #{total} messages took #{subscribe_time}\n" \
        "--------------------------------------------------------------------------------\n"
      end
      puts "\n--------------------------------------------------------------------------------\n" \
      "Roundtrip to process #{total} messages: #{roundtrip_time} (#{total/roundtrip_time} msgs/sec)\n" \
      "--------------------------------------------------------------------------------\n"
    end
  end

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
