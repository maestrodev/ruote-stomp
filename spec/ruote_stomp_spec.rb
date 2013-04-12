require File.join(File.dirname(__FILE__), 'spec_helper')

describe RuoteStomp do

  module RuoteStomp
    # access protected methods
    def self.create_connection_uri_spec(config)
      create_connection_uri(config)
    end
  end

  before(:each) do
    @config = {
      :host => "127.0.0.1",
      :port => 61613,
      :user => "u",
      :passcode => "p",
      :reliable => true,
      :ssl => nil,
      :cert => nil
    }
  end

  it "uses persistent messages by default" do
    RuoteStomp.use_persistent_messages?.should be_true
  end

  it "allows switching to transient messages" do
    RuoteStomp.use_persistent_messages = false
    RuoteStomp.use_persistent_messages?.should be_false
  end

  it "should create the correct connection url" do
    uri = RuoteStomp.create_connection_uri_spec(@config.merge({:user => nil, :passcode => nil}))
    uri.should eq("stomp://127.0.0.1:61613")
  end

  it "should create the correct connection url with user/passwd" do
    RuoteStomp.create_connection_uri_spec(@config).should eq("stomp://u:p@127.0.0.1:61613")
  end

  it "should create the correct connection url with ssl" do
    uri = RuoteStomp.create_connection_uri_spec(@config.merge({:ssl => true}))
    uri.should eq("stomp+ssl://u:p@127.0.0.1:61613")

    uri = RuoteStomp.create_connection_uri_spec(@config.merge({:ssl => false}))
    uri.should eq("stomp://u:p@127.0.0.1:61613")

    uri = RuoteStomp.create_connection_uri_spec(@config.merge({:ssl => "+ssl"}))
    uri.should eq("stomp+ssl://u:p@127.0.0.1:61613")

    uri = RuoteStomp.create_connection_uri_spec(@config.merge({:ssl => ""}))
    uri.should eq("stomp://u:p@127.0.0.1:61613")
  end
end
