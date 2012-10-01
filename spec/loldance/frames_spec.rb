require 'spec_helper'

describe Loldance::Frames do

  context "CONNECT" do

    Given(:options) { {'login' => 'admin', 'passcode' => 'password', 'host' => '127.0.0.1'} }

    When(:connect) { Loldance::Frames::Connect.new(options).to_s }

    Then { connect.should == frame(:connect) }

  end

  context "CONNECTED" do

    When(:connected) { Loldance::Frames::Connected.new frame(:connected) }

    Then { connected.headers['version'].should == "1.1" }

  end

end
