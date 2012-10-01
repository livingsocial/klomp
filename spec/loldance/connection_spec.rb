require 'spec_helper'

describe Loldance::Connection do

  Given(:data) { frame(:connected) }
  Given(:socket) { double(TCPSocket, gets:data, write:nil, set_encoding:nil) }
  Given(:server) { "127.0.0.1:61613" }
  Given(:options) { { "login" => "admin", "passcode" => "password" } }

  Given { IO.stub!(:select).and_return([[socket], [socket]])
    TCPSocket.stub!(:new).and_return socket }

  context "new" do

    When { Loldance::Connection.new server, options }

    Then do
      socket.should have_received(:set_encoding).with('UTF-8').ordered
      socket.should have_received(:write).with(frame(:connect)).ordered
      socket.should have_received(:gets).with("\x00").ordered
    end

  end

  context "new with vhost" do

    Given(:server) { "virtual-host:127.0.0.1:61613" }

    When { Loldance::Connection.new server, options }

    Then do
      TCPSocket.should have_received(:new).with("127.0.0.1", 61613)
      socket.should have_received(:write).with(frame(:connect_vhost)).ordered
    end
  end

  context "new with connection error" do

    Given(:data) { frame(:auth_error) }

    When(:expect_connect) { expect { Loldance::Connection.new server, options } }

    Then { expect_connect.to raise_error(Loldance::Error) }
  end

  context "publish" do

    Given(:connection) { Loldance::Connection.new server, options }

    When { connection.publish "/queue/greeting", "hello" }

    Then { socket.should have_received(:write).with(frame(:greeting)) }

  end

  context "subscribe" do

    Given!(:connection) { Loldance::Connection.new server, options }
    Given(:subscriber) { double "subscriber", call:nil }
    Given(:thread) { double Thread }
    Given { Thread.stub!(:new).and_return {|*args,&blk| thread.stub!(:block => blk); thread } }

    context "writes the subscribe message" do

      When { connection.subscribe "/queue/greeting", subscriber }

      Then { socket.should have_received(:write).with(frame(:subscribe)) }

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
        connection.instance_eval { @closed = true }
        thread.block.call
      end

      Then do
        subscriber.should have_received(:call).with(an_instance_of(Loldance::Frames::Message))
      end

    end

    context "fails if neither a subscriber nor a block is given" do

      When(:expect_subscribe) { expect { connection.subscribe("/queue/greeting") } }

      Then { expect_subscribe.to raise_error(Loldance::Error) }

    end

    context "fails if the subscriber does not respond to #call" do

      When(:expect_subscribe) { expect { connection.subscribe("/queue/greeting", double("subscriber")) } }

      Then { expect_subscribe.to raise_error(Loldance::Error) }

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

    Given(:connection) { Loldance::Connection.new server, options }

    Given { connection.subscriptions["/queue/greeting"] = double "subscribers" }

    When { connection.unsubscribe "/queue/greeting" }

    Then { socket.should have_received(:write).with(frame(:unsubscribe)) }

  end

  context "disconnect" do

    Given!(:connection) { Loldance::Connection.new server, options }

    When do
      socket.stub!(:close => nil)
      connection.disconnect
    end

    Then do
      socket.should have_received(:write).with(frame(:disconnect))
      socket.should have_received(:close)
    end

    context "makes connection useless (raises error)" do

      Then { expect { connection.publish "/queue/greeting", "hello" }.to raise_error(Loldance::Error) }

    end

  end

end
