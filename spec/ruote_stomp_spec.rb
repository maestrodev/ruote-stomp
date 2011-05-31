
require File.join(File.dirname(__FILE__), 'spec_helper')


describe RuoteStomp do

  it "uses persistent messages by default" do

    RuoteStomp.use_persistent_messages?.should be_true
  end

  it "allows switching to transient messages" do

    RuoteStomp.use_persistent_messages = false
    RuoteStomp.use_persistent_messages?.should be_false
  end
end

