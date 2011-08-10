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
        stomp :queue => '/queue/test3'
        echo '${f:foo}'
      end
    end
  
    @engine.register_participant(:stomp, RuoteStomp::ParticipantProxy)
  
    receiver = RuoteStomp::Receiver.new(@engine, :ignore_disconnect_on_process => true)
    
    wfid = @engine.launch(pdef)
      
    workitem = nil
      
    begin
      Timeout::timeout(5) do
      
        $stomp.subscribe("/queue/test3") do |message|
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
<<<<<<< Updated upstream

    #MQ.queue('ruote_workitems', :durable => true).send(Rufus::Json.encode(workitem.to_h), :persistent => true)
    $stomp.send '/queue/ruote_workitems', 
      Rufus::Json.encode(workitem.to_h), 
      { :persistent => true }
=======
      
    $stomp.send '/queue/ruote_workitems', Rufus::Json.encode(workitem.to_h)
>>>>>>> Stashed changes
    @engine.wait_for(wfid)
      
    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions
      
    @tracer.to_s.should == "foo\nbar"
    receiver.stop
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
    
    receiver = RuoteStomp::Receiver.new(@engine, {:launchitems => true, :unsubscribe => true, :ignore_disconnect_on_process => true})

    finished_processing = false

<<<<<<< Updated upstream
    # MQ.queue(
    #   'ruote_workitems', :durable => true
    # ).send(
    #   json, :persistent => true
    # )
    
    $stomp.send '/queue/ruote_workitems', json, { :persistent => true }
=======
    $stomp.send('/queue/ruote_workitems', json) do |r|
      finished_processing = true
    end
    
    begin
      Timeout::timeout(20) do
        while @tracer.to_s.empty?
          print "*"
          sleep 1
        end
      end
    rescue Timeout::Error
      fail "Timeout waiting for message"
    end
>>>>>>> Stashed changes
    
    Thread.pass until finished_processing

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == 'bar'
    receiver.stop
  end

  it 'accepts a custom :queue' do
  
    RuoteStomp::Receiver.new(
      @engine, :queue => '/queue/mario', :launchitems => true, :unsubscribe => true, :ignore_disconnect_on_process => true)
  
    @engine.register_participant 'alpha', Ruote::StorageParticipant
  
    json = Rufus::Json.encode({
      'definition' => "Ruote.define { alpha }"
    })
<<<<<<< Updated upstream

    # MQ.queue(
    #   'ruote_workitems', :durable => true
    # ).send(
    #   json, :persistent => true
    # )
    
    $stomp.send '/queue/ruote_workitems', 
      json, 
      { :persistent => true }

=======
    
    $stomp.send '/queue/ruote_workitems', json
  
>>>>>>> Stashed changes
    sleep 1
  
    @engine.processes.size.should == 0
      # nothing happened
<<<<<<< Updated upstream

    # MQ.queue(
    #   'mario', :durable => true
    # ).send(
    #   json, :persistent => true
    # )
    
    $stomp.send '/queue/mario', 
      json, 
      { :persistent => true }

=======
  
    $stomp.send '/queue/mario', json
  
>>>>>>> Stashed changes
    sleep 1
  
    @engine.processes.size.should == 1
      # launch happened
  end
end

