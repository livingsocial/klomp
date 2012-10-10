require 'spec_helper'

describe Klomp::Connection do

  Given(:data)       { frame(:connected) }
  Given(:server)     { "127.0.0.1:61613" }
  Given(:options)    { { "login" => "admin", "passcode" => "password", "logger" => logger } }
  Given(:socket)     { double(TCPSocket, gets:data, write:nil, set_encoding:nil, close:nil) }
  Given(:logger)     { double("Logger", error:nil, warn:nil, info:nil, debug:nil).as_null_object }
  Given(:subscriber) { double "subscriber", call:nil }
  Given(:thread)     { double Thread }
  Given(:sentinel)   { double Klomp::Sentinel, alive?:true }

  Given do
    IO.stub!(:select).and_return([[socket], [socket]])
    TCPSocket.stub!(:new).and_return socket
    Thread.stub!(:new).and_return {|*args,&blk| thread.stub!(:block => blk); thread }
    Klomp::Sentinel.stub!(new: sentinel)
  end

  context "new" do

    When { Klomp::Connection.new server, options }

    Then do
      socket.should have_received(:set_encoding).with('UTF-8').ordered
      socket.should have_received(:write).with(frame(:connect)).ordered
      socket.should have_received(:gets).with("\x00").ordered
    end

  end

  context "new with vhost" do

    Given(:server) { "virtual-host:127.0.0.1:61613" }

    When { Klomp::Connection.new server, options }

    Then do
      TCPSocket.should have_received(:new).with("127.0.0.1", 61613)
      socket.should have_received(:write).with(frame(:connect_vhost)).ordered
    end

  end

  context "new with stomp:// URL" do

    Given(:server) { "stomp://admin:password@127.0.0.1:61613?host=virtual-host" }
    Given(:options) { {} }

    When { Klomp::Connection.new server, options }

    Then do
      TCPSocket.should have_received(:new).with("127.0.0.1", 61613)
      socket.should have_received(:write).with(frame(:connect_vhost)).ordered
    end

  end

  context "new with connection error" do

    Given(:data) { frame(:auth_error) }

    When(:expect_connect) { expect { Klomp::Connection.new server, options } }

    Then { expect_connect.to raise_error(Klomp::Error) }
  end

  context "publish" do

    Given(:connection) { Klomp::Connection.new server, options }

    When(:result) { connection.publish "/queue/greeting", "hello" }

    Then { socket.should have_received(:write).with(frame(:greeting)) }

    Then { result.should be_instance_of(Klomp::Frames::Send) }

    context "logs when logger level is debug" do

      Given(:logger) { double("Logger").as_null_object.tap {|l| l.stub!(debug?: true) } }

      Then { logger.should have_received(:debug) }

    end

  end

  context "subscribe" do

    Given!(:connection) { Klomp::Connection.new server, options }

    context "writes the subscribe message" do

      When(:result) { connection.subscribe "/queue/greeting", subscriber }

      Then { socket.should have_received(:write).with(frame(:subscribe)) }

      Then { result.should be_instance_of(Klomp::Frames::Subscribe) }

      context "and logs when logger level is debug" do

        Given(:logger) { double("Logger").as_null_object.tap {|l| l.stub!(debug?: true) } }

        Then { logger.should have_received(:debug) }

      end

    end

    context "called twice writes to the socket only once" do

      When do
        connection.subscribe "/queue/greeting", subscriber
        connection.subscribe "/queue/greeting", double("another subscriber that replaces the first", call:nil)
      end

      Then { socket.should have_received(:write).with(frame(:subscribe)).once }

    end

    context "and accepts a block as the subscriber" do

      When { connection.subscribe("/queue/foo") { true } }

      Then { connection.subscriptions["/queue/foo"].call.should == true }

    end

    context "and accepts an object that responds to #call as the subscriber" do

      When { connection.subscribe("/queue/foo", subscriber) }

      Then { connection.subscriptions["/queue/foo"].should == subscriber }

    end

    context "and dispatches to the message callback" do

      When do
        connection.subscribe "/queue/greeting", subscriber
        socket.stub!(:gets).and_return frame(:message)
        connection.send :close!
        thread.block.call
      end

      Then do
        subscriber.should have_received(:call).with(an_instance_of(Klomp::Frames::Message))
      end

    end

    context "does not dispatch if an error frame was read" do

      When do
        connection.subscribe "/queue/greeting", subscriber
        socket.stub!(:gets).and_return frame(:error)
        connection.send :close!
        thread.block.call
      end

      Then { subscriber.should_not have_received(:call) }

      Then { logger.should have_received(:warn) }

    end

    context "fails if neither a subscriber nor a block is given" do

      When(:expect_subscribe) { expect { connection.subscribe("/queue/greeting") } }

      Then { expect_subscribe.to raise_error(Klomp::Error) }

    end

    context "fails if the subscriber does not respond to #call" do

      When(:expect_subscribe) { expect { connection.subscribe("/queue/greeting", double("subscriber")) } }

      Then { expect_subscribe.to raise_error(Klomp::Error) }

    end

    context "subscriptions" do

      context "is not empty after subscribing" do

        When { connection.subscribe("/queue/greeting") { true } }

        Then { connection.subscriptions.length.should == 1 }

        context "and empty after unsubscribing" do

          When { connection.unsubscribe("/queue/greeting") }

          Then { connection.subscriptions.length.should == 0 }

        end

      end

    end

  end

  context "unsubscribe" do

    Given(:connection) { Klomp::Connection.new server, options }
    Given(:arg) { "/queue/greeting" }

    Given { connection.subscriptions["/queue/greeting"] = double "subscribers" }

    When(:result) { connection.unsubscribe arg }

    Then { socket.should have_received(:write).with(frame(:unsubscribe)) }

    Then { result.should be_instance_of(Klomp::Frames::Unsubscribe) }

    context "can accept Subscribe frame" do

      Given(:arg) { Klomp::Frames::Subscribe.new "/queue/greeting" }

      Then { socket.should have_received(:write).with(frame(:unsubscribe)) }

    end
  end

  context "disconnect" do

    Given!(:connection) { Klomp::Connection.new server, options }

    When(:result) { connection.disconnect }

    Then do
      socket.should have_received(:write).with(frame(:disconnect))
      socket.should have_received(:close)
    end

    Then { result.should be_instance_of(Klomp::Frames::Disconnect) }

    context "makes connection useless (raises error)" do

      Then { expect { connection.publish "/queue/greeting", "hello" }.to raise_error(Klomp::Error) }

    end

  end

  context "socket error on write causes connection to be disconnected" do

    Given!(:connection) { Klomp::Connection.new server, options }
    Given do
      socket.stub!(:write).and_raise SystemCallError.new("some socket error")
    end

    When(:expect_publish) { expect { connection.publish "/queue/greeting", "hello" } }

    Then do
      expect_publish.to raise_error(SystemCallError)
      connection.should_not be_connected
    end

    context "and subsequent calls raise Klomp::Error" do

      Then do
        expect_publish.to raise_error(SystemCallError)
        expect_publish.to raise_error(Klomp::Error)
      end

    end

    context "and starts reconnect sentinel" do

      Then do
        expect_publish.to raise_error(SystemCallError)
        Klomp::Sentinel.should have_received(:new).with(connection)
      end

      context "only once" do

        Then do
          expect_publish.to raise_error(SystemCallError)
          connection.send(:go_offline, begin; raise "error"; rescue; $!; end)
          Klomp::Sentinel.should have_received(:new).with(connection).once
        end

      end

    end

  end

  context "socket error on read causes connection to be disconnected" do

    Given!(:connection) { Klomp::Connection.new server, options }

    Given do
      thread.stub!(:raise).and_return {|e| raise e }
      socket.stub!(:gets).and_raise SystemCallError.new("some socket error")
    end

    When do
      connection.subscribe "/queue/greeting", subscriber
      thread.block.call
    end

    Then { connection.should_not be_connected }

  end

  context "reconnect" do

    Given!(:connection) { Klomp::Connection.new server, options }

    context "creates new socket" do

      Given { connection.disconnect }

      When { connection.reconnect }

      Then { connection.should be_connected }

      Then { logger.should have_received(:warn) }

    end

    context "has no effect if connection is already connected" do

      Given { socket.messages_received.clear }

      When { connection.reconnect }

      Then { connection.should be_connected }

      Then { socket.should_not have_received(:write) }

    end

    context "re-subscribes all subscriptions" do

      Given do
        connection.subscribe "/queue/greeting", subscriber
        thread.stub!(:raise)
        connection.disconnect
        socket.messages_received.clear
      end

      When { connection.reconnect }

      Then { socket.should have_received(:write).with(frame(:subscribe)) }

    end

  end

end
