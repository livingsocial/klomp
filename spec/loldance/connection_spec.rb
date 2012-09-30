require 'spec_helper'

describe Loldance::Connection do

  Given(:data) { frame(:connected) }
  Given(:socket) { double(TCPSocket, gets:data, write:nil, set_encoding:nil) }
  Given(:server) { "127.0.0.1:61613" }
  Given(:options) { { "login" => "admin", "password" => "password" } }

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

  context "publish" do

    Given(:connection) { Loldance::Connection.new server, options }

    When { connection.publish "/queue/greeting", "hello" }

    Then do
      socket.should have_received(:write).with(frame(:greeting))
    end

  end

end
