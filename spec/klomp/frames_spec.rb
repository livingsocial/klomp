require 'spec_helper'

describe Klomp::Frames do

  Given(:options) { {'login' => 'admin', 'passcode' => 'password', 'host' => '127.0.0.1'} }

  context "CONNECT" do


    When(:connect) { Klomp::Frames::Connect.new(options).to_s }

    Then { connect.should == frame(:connect) }

  end

  context "CONNECTED" do

    When(:connected) { Klomp::Frames::Connected.new frame(:connected) }

    Then { connected.headers['version'].should == "1.1" }

  end

  context "#[] is an alias for #headers" do

    When(:connect) { Klomp::Frames::Connect.new(options) }

    When { connect['my-header'] = 'my-value' }

    Then { connect['login'].should == 'admin' }

    Then { connect['passcode'].should == 'password' }

    Then { connect['my-header'].should == 'my-value' }

  end

  context "body can be assigned after construction" do

    Given(:send_frame) { Klomp::Frames::Send.new("/queue/q", "", {}) }

    When { send_frame.body = "hello" }

    Then { send_frame.body.should == "hello" }

  end

end
