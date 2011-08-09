
require File.join(File.dirname(__FILE__), 'spec_helper')

#
# NOTE : RuoteStomp::WorkitemListener has been depreacted in favour of
#        RuoteStomp::Receiver
#


describe RuoteStomp::WorkitemListener do

  after(:each) do
    purge_engine
  end

  it "handles replies" do

    pdef = Ruote.process_definition :name => 'test' do
      set :field => 'foo', :value => 'foo'
      sequence do
        echo '${f:foo}'
        stomp :queue => '/queue/test7'
        echo '${f:foo}'
      end
    end

    @engine.register_participant(:stomp, RuoteStomp::ParticipantProxy)

    RuoteStomp::WorkitemListener.new(@engine, :unsubscribe => true)

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    workitem = nil

    begin
      Timeout::timeout(5) do

        # MQ.queue('test7', :durable => true).subscribe { |msg|
        #   wi = Ruote::Workitem.new(Rufus::Json.decode(msg))
        #   workitem = wi if wi.wfid == wfid
        # }
        
        $stomp.subscribe("/queue/test7", {:persistent => true}) do |message|
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

    workitem.fields['foo'] = 'bar'

    #MQ.queue('ruote_workitems', :durable => true).send(Rufus::Json.encode(workitem.to_h), :persistent => true)
    $stomp.send '/queue/ruote_workitems', 
      Rufus::Json.encode(workitem.to_h), 
      { :persistent => true }
      
    @engine.wait_for(wfid)

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == "foo\nbar"
  end
end

