require 'stomp'

require 'ruote-stomp/version'


#
# Stomp participant and listener pair for ruote.
#
# == Documentation
#
# See #RuoteStomp::Listener and #RuoteStomp::Participant for detailed
# documentation on using each of them.
#
# == Stomp Notes
#
# RuoteAmqp uses durable queues and persistent messages by default, to ensure
# no messages get lost along the way and that running expressions doesn't have
# to be restarted in order for messages to be resent. <- not exactly sure yet
# how RuoteStomp will handle durable queues, messages are persisted.
#
module RuoteStomp

  autoload 'ParticipantProxy',   'ruote-stomp/participant'

  autoload 'Receiver',           'ruote-stomp/receiver'
  autoload 'WorkitemListener',   'ruote-stomp/workitem_listener'
  autoload 'LaunchitemListener', 'ruote-stomp/launchitem_listener'

  class << self

    attr_writer :use_persistent_messages
    
    # Whether or not to use persistent messages (true by default)
    def use_persistent_messages?
      @use_persistent_messages = true if @use_persistent_messages.nil?
      @use_persistent_messages
    end

    # Ensure the Stomp connection is started
    def start!
      return if started?

      mutex = Mutex.new
      cv = ConditionVariable.new

      Thread.main[:ruote_stomp_connection] = Thread.new do
        Thread.abort_on_exception = true
        
        begin
          $stomp = Stomp::Client.new STOMP.settings[:user], 
                                     STOMP.settings[:passcode], 
                                     STOMP.settings[:host], 
                                     STOMP.settings[:port], 
                                     STOMP.settings[:reliable]
          if $stomp
            started!
            cv.signal
          end
        rescue
          raise RuntimeError, "Failed to connect to Stomp server."
        end
      end

      mutex.synchronize { cv.wait(mutex) }

      # Stomp equivalent?
      #MQ.prefetch(1)

      yield if block_given?
    end

    # Check whether the AMQP connection is started
    def started?
      Thread.main[:ruote_stomp_started] == true
    end

    def started! #:nodoc:
      Thread.main[:ruote_stomp_started] = true
    end

    # Close down the Stomp connections
    def stop!
      return unless started?
      $stomp.close
      Thread.main[:ruote_stomp_connection].join
      Thread.main[:ruote_stomp_started] = false
    end
  end
end

module STOMP
  def self.settings
    @settings ||= {:host => "localhost", :port => "61613", :reliable => false}
  end
end

