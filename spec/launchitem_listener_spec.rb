
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

    RuoteStomp::LaunchitemListener.new(@engine)

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
  end

  it 'discards corrupt process definitions' do

    json = {
      'definition' => %{
        I'm a broken process definition
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteStomp::LaunchitemListener.new(@engine, :unsubscribe => true)

    serr = String.new
    err = StringIO.new(serr, 'w+')
    $stderr = err

    $stomp.send '/queue/ruote_launchitems', json, { :persistent => true }

    #MQ.queue('ruote_launchitems', :durable => true).send(json)

    sleep 0.5

    err.close
    $stderr = STDERR

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == ''

    serr.should match(/^===/)
  end
end

