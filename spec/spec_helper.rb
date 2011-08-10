require 'rubygems'
require 'rspec'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../../ruote/lib'))

require 'fileutils'
require 'json'
require 'timeout'

require 'ruote/engine'
require 'ruote/worker'
require 'ruote/storage/hash_storage'
require 'ruote/log/test_logger'
#require 'stomp_server'

require 'ruote-stomp'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |path|
  require(path)
}

# No Stomp auth is configured/required.
# test = Thread.new do
#   EventMachine::run do
#     config = StompServer::Configurator.new
#     stomp = StompServer::Run.new(config.opts)
#     stomp.start
# 
#     puts "Stomp protocol handler starting on #{config.opts[:host]} port #{config.opts[:port]}"
#     EventMachine.start_server(config.opts[:host], 
#                               config.opts[:port], 
#                               StompServer::Protocols::Stomp) do |s| 
#       s.instance_eval {
#         @@auth_required = false
#         @@queue_manager = stomp.queue_manager
#         @@topic_manager = stomp.topic_manager
#         @@stompauth = stomp.stompauth
#       }
#     end
#   end
# end

STOMP.settings[:user]     = ""
STOMP.settings[:passcode] = ""
STOMP.settings[:host]     = "127.0.0.1"
STOMP.settings[:port]     = 61613
STOMP.settings[:reliable] = true

RSpec.configure do |config|

#  config.fail_fast = true

  config.include(RuoteSpecHelpers)
  
  config.before(:each) do
    @tracer = Tracer.new
    @engine = Ruote::Engine.new(
      Ruote::Worker.new(
        Ruote::HashStorage.new('s_logger' => [ 'ruote/log/test_logger', 'Ruote::TestLogger' ])
      )
    )
    
    @engine.add_service('tracer', @tracer)
    #@engine.noisy = true
  end

  config.after(:each) do
    @engine.context.storage.purge!
    @engine.shutdown
  end

  config.after(:all) do
    base = File.expand_path(File.dirname(__FILE__) + '/..')
    FileUtils.rm_rf(base + '/logs')
    FileUtils.rm_rf(base + '/work')
  end
end

class Tracer
  def initialize
    @trace = ''
  end
  def to_s
    @trace.to_s.strip
  end
  def << s
    @trace << s
  end
  def clear
    @trace = ''
  end
  def puts s
    @trace << "#{s}\n"
  end
end

