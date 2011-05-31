
require File.join(File.dirname(__FILE__), 'spec_helper')

require 'ruote/participant'


describe RuoteStomp::Receiver do

  after(:each) do
    purge_engine
  end

  it "handles replies" do

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'foo', :value => 'foo'
      sequence do
        echo '${f:foo}'
        amqp :queue => '/queue/test3'
        echo '${f:foo}'
      end
    end

    @engine.register_participant(:amqp, RuoteStomp::ParticipantProxy)

    RuoteStomp::Receiver.new(@engine)

    wfid = @engine.launch(pdef)

    workitem = nil

    begin
      Timeout::timeout(5) do

        # MQ.queue('test3', :durable => true).subscribe { |msg|
        #   wi = Ruote::Workitem.new(Rufus::Json.decode(msg))
        #   workitem = wi if wi.wfid == wfid
        # }
        
        $stomp.subscribe("/queue/test3", {}) do |message|
          wi = Ruote::Workitem.new(Rufus::Json.decode(message.body))
          workitem = wi if wi.wfid == wfid
        end

        loop do
          break unless workitem.nil?
          sleep 0.1
        end
      end
    rescue Timeout::Error
      fail "Timeout waiting for message"
    end

    workitem.fields['foo'] = "bar"

    #MQ.queue('ruote_workitems', :durable => true).publish(Rufus::Json.encode(workitem.to_h), :persistent => true)
    $stomp.publish '/queue/ruote_workitems', 
      Rufus::Json.encode(workitem.to_h), 
      { :persistent => true }
    @engine.wait_for(wfid)

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"
  end

  it "launches processes" do

    json = {
      'definition' => %{
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteStomp::Receiver.new(@engine, :launchitems => true, :unsubscribe => true)

    # MQ.queue(
    #   'ruote_workitems', :durable => true
    # ).publish(
    #   json, :persistent => true
    # )
    
    $stomp.publish '/queue/ruote_workitems', json, { :persistent => true }
    

    sleep 0.5

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == 'bar'
  end

  it 'accepts a custom :queue' do

    RuoteStomp::Receiver.new(
      @engine, :queue => '/queue/mario', :launchitems => true, :unsubscribe => true)

    @engine.register_participant 'alpha', Ruote::StorageParticipant

    json = Rufus::Json.encode({
      'definition' => "Ruote.define { alpha }"
    })

    # MQ.queue(
    #   'ruote_workitems', :durable => true
    # ).publish(
    #   json, :persistent => true
    # )
    
    $stomp.publish '/queue/ruote_workitems', 
      json, 
      { :persistent => true }

    sleep 1

    @engine.processes.size.should == 0
      # nothing happened

    # MQ.queue(
    #   'mario', :durable => true
    # ).publish(
    #   json, :persistent => true
    # )
    
    $stomp.publish '/queue/mario', 
      json, 
      { :persistent => true }

    sleep 1

    @engine.processes.size.should == 1
      # launch happened
  end
end

