require File.join(File.dirname(__FILE__), 'spec_helper')

describe RuoteStomp::LaunchitemListener do

  after(:each) do
    purge_engine
  end

  it 'launches processes' do

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

    RuoteStomp::LaunchitemListener.new(@engine, :ignore_disconnect_on_process => true)

<<<<<<< Updated upstream
    $stomp.send '/queue/ruote_launchitems', json, { :persistent => true }
    #MQ.queue('ruote_launchitems', :durable => true).send(json)


    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions
    
    begin
      Timeout::timeout(10) do
        while @tracer.to_s != 'bar'
          print "*"
          sleep 1
        end
      end
    rescue Timeout::Error
      fail "Timeout waiting for message"
    end
=======
    finished_processing = false

    $stomp.send('/queue/ruote_launchitems', json) do |r|
      finished_processing = true
    end
    
    begin
      Timeout::timeout(10) do
        while @tracer.to_s.empty?
          print "*"
          sleep 1
        end
      end
    rescue Timeout::Error
      fail "Timeout waiting for message"
    end
    
    Thread.pass until finished_processing

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions
    @tracer.to_s.should == 'bar'
>>>>>>> Stashed changes
  end

  it 'discards corrupt process definitions' do
  
    json = {
      'definition' => %{
        I'm a broken process definition
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json
  
    RuoteStomp::LaunchitemListener.new(@engine, {:unsubscribe => true, :ignore_disconnect_on_process => true})
  
    serr = String.new
    err = StringIO.new(serr, 'w+')
    $stderr = err
<<<<<<< Updated upstream

    $stomp.send '/queue/ruote_launchitems', json, { :persistent => true }

    #MQ.queue('ruote_launchitems', :durable => true).send(json)

=======
  
    $stomp.send '/queue/ruote_launchitems', json
  
>>>>>>> Stashed changes
    sleep 0.5
  
    err.close
    $stderr = STDERR
  
    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions
  
    @tracer.to_s.should == ''
  
    serr.should match(/^===/)
  end
end

