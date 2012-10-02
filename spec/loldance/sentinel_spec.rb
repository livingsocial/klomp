require 'spec_helper'

describe Loldance::Sentinel do

  Given(:connection) { double "Connection", connected?:false, reconnect:nil }
  Given(:sentinel) { Loldance::Sentinel.new connection }
  Given(:thread) { double Thread }
  Given do
    Thread.stub!(:new).and_return {|*args,&blk| thread.stub!(:block => blk); thread }
  end

  context "does nothing if the connection is already connected" do

    Given { connection.stub!(connected?: true) }

    When { sentinel }

    Then { Thread.should_not have_received(:new) }

  end

  context "reconnects the connection" do

    When { sentinel ; thread.block.call }

    Then { connection.should have_received(:reconnect) }

  end

  context "does fibonacci backoff if reconnection fails" do

    Given(:number_of_reconnects) { 7 }
    Given do
      count = 0
      connection.stub!(:reconnect).and_return { count += 1; raise Loldance::Error if count < number_of_reconnects }
    end

    When do
      sentinel.stub!(:sleep)
      thread.block.call
    end

    Then do
      connection.should have_received(:reconnect).exactly(number_of_reconnects).times
    end

    Then do
      sentinel.should have_received(:sleep).with(1).twice
      sentinel.should have_received(:sleep).with(2)
      sentinel.should have_received(:sleep).with(3)
      sentinel.should have_received(:sleep).with(5)
      sentinel.should have_received(:sleep).with(8)
    end

  end

end
