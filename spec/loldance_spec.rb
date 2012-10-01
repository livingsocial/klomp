require 'spec_helper'

describe Loldance do

  Given(:servers) { ["127.0.0.1:61613", "127.0.0.1:67673"] }
  Given(:connections) { Hash[*servers.map {|s| [s, double("connection #{s}")] }.flatten] }
  Given { Loldance::Connection.stub!(:new).and_return {|s| connections[s] } }
  Given(:loldance) { Loldance.new servers }

  context "new" do

    context "raises ArgumentError" do

      context "when created with no arguments" do

        When(:expect_new) { expect { Loldance.new } }

        Then { expect_new.to raise_error(ArgumentError) }

      end

      context "when created with an empty array" do

        When(:expect_new) { expect { Loldance.new([]) } }

        Then { expect_new.to raise_error(ArgumentError) }

      end

    end

    context "creates a Loldance::Connection for each server" do

      Given { Loldance::Connection.stub!(:new).and_return double(Loldance::Connection) }

      When(:loldance) { Loldance.new servers }

      Then { servers.each {|s| Loldance::Connection.should have_received(:new).with(s, {}) } }

    end

  end

  context "publish" do

    context "calls publish on one of the connections" do

      Given do
        connections.values.each do |conn|
          conn.stub!(:connected? => false)
          conn.stub!(:publish).and_return { conn.stub!(:connected? => true) }
        end
      end

      When { loldance.publish "/queue/greeting", "hello" }

      Then { connections.values.select {|conn| conn.connected? }.length.should == 1 }

      Then { connections.values.detect {|conn| conn.connected? }.
        should have_received(:publish).with("/queue/greeting", "hello", {}) }

    end

    context "calls publish on another connection if the first one fails" do

      Given do
        first_exception = false
        connections.values.each do |conn|
          conn.stub!(:connected? => false)
          conn.stub!(:publish).and_return do
            if first_exception
              conn.stub!(:connected? => true)
            else
              first_exception = true
              raise Loldance::Error.new
            end
          end
        end
      end

      When { loldance.publish "/queue/greeting", "hello" }

      Then { connections.values.select {|conn| conn.connected? }.length.should == 1 }

      Then { connections.values.detect {|conn| conn.connected? }.
        should have_received(:publish).with("/queue/greeting", "hello", {}) }

    end

    context "raises an exception if all connections failed" do

      Given { connections.values.each {|conn| conn.stub!(:publish).and_raise(Loldance::Error.new) } }

      When(:expect_publish) { expect { loldance.publish "/queue/greeting", "hello" } }

      Then do
        expect_publish.to raise_error(Loldance::Error)
        connections.values.each {|conn| conn.should have_received(:publish) }
      end

    end

  end

  context "subscribe" do

    context "calls subscribe on all of the servers" do

      Given { connections.values.each {|conn| conn.stub!(:subscribe) } }

      When { loldance.subscribe("/queue/greeting") { true } }

      Then { connections.values.each {|conn| conn.should have_received(:subscribe).with("/queue/greeting", nil) } }

    end

    context "fails if any subscribe calls fail" do

      Given { connections.values.each {|conn| conn.stub!(:subscribe).and_raise(Loldance::Error.new) } }

      When(:expect_publish) { expect { loldance.subscribe("/queue/greeting") { true } } }

      Then { expect_publish.to raise_error(Loldance::Error) }

    end

  end

  context "unsubscribe" do

    context "calls unsubscribe on all the servers" do

      Given { connections.values.each {|conn| conn.stub!(:unsubscribe) } }

      When { loldance.unsubscribe("/queue/greeting") }

      Then { connections.values.each {|conn| conn.should have_received(:unsubscribe).with("/queue/greeting") } }

    end

    context "calls unsubscribe on all the servers even if the unsubscribe errs" do

      Given { connections.values.each {|conn| conn.stub!(:unsubscribe).and_raise Loldance::Error.new } }

      When { loldance.unsubscribe("/queue/greeting") }

      Then { connections.values.each {|conn| conn.should have_received(:unsubscribe).with("/queue/greeting") } }

    end

  end

  context "disconnect" do

    context "disconnects all the servers" do

      Given { connections.values.each {|conn| conn.stub!(:disconnect) } }

      When { loldance.disconnect }

      Then { connections.values.each {|conn| conn.should have_received(:disconnect) } }

    end

  end

end
