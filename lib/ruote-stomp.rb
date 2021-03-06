require 'onstomp'

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
          if STOMP.settings[:ssl]
            $stomp = OnStomp::Client.new(create_connection_uri(STOMP.settings),
              :ssl => {
                :ca_file => STOMP.settings[:cert],
                :verify_mode => OpenSSL::SSL::VERIFY_NONE
              }
            )
            $stomp.connect
          else
            $stomp = OnStomp.connect create_connection_uri(STOMP.settings)
          end
          
          if $stomp && $stomp.connected?
            started!
            cv.signal
          end
        rescue Exception => e
          raise e, "Failed to connect to Stomp server: #{e.message}"
        end
      end

      mutex.synchronize { cv.wait(mutex) }

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
      $stomp.disconnect
      Thread.main[:ruote_stomp_connection].join
      Thread.main[:ruote_stomp_started] = false
    end
    
    protected
    
    def create_connection_uri(config={})
      user = config[:user]
      passcode = config[:passcode]
      host = config[:host]
      port = config[:port].to_s
      ssl = (config[:ssl] and !config[:ssl].to_s.empty?) ? "+ssl" : ""
      cert = config[:cert] || ""
      
      # construct the connection URI
      user_and_password = [user,passcode].reject{|e| e.nil? || e.empty?}.join(":")
      host_and_port = [host,port].reject{|e| e.nil? || e.empty?}.join(":")
      uri = [host_and_port, user_and_password].reject{|e| e.nil? || e.empty?}.reverse.join("@")
      protocol = ['stomp', ssl, '://'].reject{|e| e.nil? || e.empty?}.join
      
      "#{protocol}#{uri}"
    end
  end
end

module STOMP
  def self.settings
    @settings ||= {:host => "localhost", :port => "61613"}
  end
end

