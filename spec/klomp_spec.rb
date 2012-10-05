require 'spec_helper'

describe Klomp do

  Given(:servers) { ["127.0.0.1:61613", "127.0.0.1:67673"] }
  Given(:connections) { Hash[*servers.map {|s| [s, double("connection #{s}")] }.flatten] }
  Given { Klomp::Connection.stub!(:new).and_return {|s| connections[s] } }
  Given(:klomp) { Klomp.new servers }

  context "new" do

    context "raises ArgumentError" do

      context "when created with no arguments" do

        When(:expect_new) { expect { Klomp.new } }

        Then { expect_new.to raise_error(ArgumentError) }

      end

      context "when created with an empty array" do

        When(:expect_new) { expect { Klomp.new([]) } }

        Then { expect_new.to raise_error(ArgumentError) }

      end

    end

    context "creates a Klomp::Connection for each server" do

      Given { Klomp::Connection.stub!(:new).and_return double(Klomp::Connection) }

      When(:klomp) { Klomp.new servers }

      Then { servers.each {|s| Klomp::Connection.should have_received(:new).with(s, {}) } }

    end

  end

  context "publish" do

    Given(:frame) { double "send frame" }

    context "calls publish on one of the connections" do

      Given do
        connections.values.each do |conn|
          conn.stub!(:connected? => false)
          conn.stub!(:publish).and_return { conn.stub!(:connected? => true); frame }
        end
      end

      When(:result) { klomp.publish "/queue/greeting", "hello" }

      Then { connections.values.select {|conn| conn.connected? }.length.should == 1 }

      Then { connections.values.detect {|conn| conn.connected? }.
        should have_received(:publish).with("/queue/greeting", "hello", {}) }

      Then { result.should == frame }

    end

    context "calls publish on another connection if the first one fails" do

      Given do
        first_exception = false
        connections.values.each do |conn|
          conn.stub!(:connected? => false)
          conn.stub!(:publish).and_return do
            if first_exception
              conn.stub!(:connected? => true)
              frame
            else
              first_exception = true
              raise Klomp::Error.new
            end
          end
        end
      end

      When(:result) { klomp.publish "/queue/greeting", "hello" }

      Then { connections.values.select {|conn| conn.connected? }.length.should == 1 }

      Then { connections.values.detect {|conn| conn.connected? }.
        should have_received(:publish).with("/queue/greeting", "hello", {}) }

      Then { result.should == frame }

    end

    context "raises an exception if all connections failed" do

      Given { connections.values.each {|conn| conn.stub!(:publish).and_raise(Klomp::Error.new) } }

      When(:expect_publish) { expect { klomp.publish "/queue/greeting", "hello" } }

      Then do
        expect_publish.to raise_error(Klomp::Error)
        connections.values.each {|conn| conn.should have_received(:publish) }
      end

    end

  end

  context "subscribe" do

    context "calls subscribe on all of the servers" do

      Given { connections.values.each {|conn| conn.stub!(:subscribe) } }

      When { klomp.subscribe("/queue/greeting") { true } }

      Then { connections.values.each {|conn| conn.should have_received(:subscribe).with("/queue/greeting", nil) } }

    end

    context "fails if any subscribe calls fail" do

      Given { connections.values.each {|conn| conn.stub!(:subscribe).and_raise(Klomp::Error.new) } }

      When(:expect_publish) { expect { klomp.subscribe("/queue/greeting") { true } } }

      Then { expect_publish.to raise_error(Klomp::Error) }

    end

  end

  context "unsubscribe" do

    context "calls unsubscribe on all the servers" do

      Given { connections.values.each {|conn| conn.stub!(:unsubscribe) } }

      When { klomp.unsubscribe("/queue/greeting") }

      Then { connections.values.each {|conn| conn.should have_received(:unsubscribe).with("/queue/greeting") } }

    end

    context "calls unsubscribe on all the servers even if the unsubscribe errs" do

      Given { connections.values.each {|conn| conn.stub!(:unsubscribe).and_raise Klomp::Error.new } }

      When { klomp.unsubscribe("/queue/greeting") }

      Then { connections.values.each {|conn| conn.should have_received(:unsubscribe).with("/queue/greeting") } }

    end

  end

  context "disconnect" do

    context "disconnects all the servers" do

      Given { connections.values.each {|conn| conn.stub!(:disconnect) } }

      When { klomp.disconnect }

      Then { connections.values.each {|conn| conn.should have_received(:disconnect) } }

    end

  end

end
