require 'spec_helper'

describe Klomp::Frames do

  context "CONNECT" do

    Given(:options) { {'login' => 'admin', 'passcode' => 'password', 'host' => '127.0.0.1'} }

    When(:connect) { Klomp::Frames::Connect.new(options).to_s }

    Then { connect.should == frame(:connect) }

  end

  context "CONNECTED" do

    When(:connected) { Klomp::Frames::Connected.new frame(:connected) }

    Then { connected.headers['version'].should == "1.1" }

  end

end
