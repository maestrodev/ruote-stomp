require 'ruote-stomp'
module RuoteStomp

  #
  # = Stomp Receiver
  #
  # Used in conjunction with the RuoteStomp::Participant, the WorkitemListener
  # subscribes to a specific direct exchange and monitors for
  # incoming workitems. It expects workitems to arrive serialized as
  # JSON.
  #
  # == Configuration
  #
  # Stomp configuration is handled by directly manipulating the values of
  # the +Stomp.settings+ hash, as provided by the Stomp gem. No
  # defaults are set by the listener. The only +option+ parsed by
  # the initializer of the workitem listener is the +queue+ key (Hash
  # expected). If no +queue+ key is set, the listener will subscribe
  # to the +ruote_workitems+ direct exchange for workitems, otherwise it will
  # subscribe to the direct exchange provided.
  #
  # == Usage
  #
  # Register the engine or storage with the listener:
  #
  #   RuoteStomp::Receiver.new(engine_or_storage)
  #
  # The workitem listener leverages the asynchronous nature of the stomp gem,
  # so no timers are setup when initialized.
  #
  # == Options
  #
  # :queue and :launchitems
  #
  # See the RuoteStomp::Participant docs for information on sending
  # workitems out to remote participants, and have them send replies
  # to the correct direct exchange specified in the workitem
  # attributes.
  #
  class Receiver < Ruote::Receiver

    attr_reader :queue

    # Starts a new Receiver
    #
    # Two arguments for this method.
    #
    # The first one should be a Ruote::Engine, a Ruote::Storage or
    # a Ruote::Worker instance.
    #
    # The second one is a hash for options. There are two known options :
    #
    # :queue for setting the queue on which to listen (defaults to
    # 'ruote_workitems').
    #
    # :ignore_disconnect_on_process => true|false (defauts to false)
    # processes the message even if the client has disconnected (use in testing only)
    # 
    # The :launchitems option :
    #
    #   :launchitems => true
    #     # the receiver accepts workitems and launchitems
    #   :launchitems => false
    #     # the receiver only accepts workitems
    #   :launchitems => :only
    #     # the receiver only accepts launchitems
    #
    def initialize(engine_or_storage, opts={})

      super(engine_or_storage)

      @launchitems = opts[:launchitems]
      ignore_disconnect = opts[:ignore_disconnect_on_process]

      @queue =
<<<<<<< Updated upstream
      opts[:queue] ||
      (@launchitems == :only ? '/queue/ruote_launchitems' : '/queue/ruote_workitems')
=======
        opts[:queue] ||
        (@launchitems == :only ? '/queue/ruote_launchitems' : '/queue/ruote_workitems')
        
        puts "the queue is #{@queue}"
>>>>>>> Stashed changes

      RuoteStomp.start!

      if opts[:unsubscribe]
        begin
          $stomp.unsubscribe(@queue)
        rescue OnStomp::UnsupportedCommandError => e
          $stderr.puts("Connection does support unsubscribe")
        end
        sleep 0.300
      end
<<<<<<< Updated upstream
        $stomp.subscribe(@queue) do |message|
          handle(message) if $stomp.connected?
=======

      $stomp.subscribe(@queue) do |message|
        # Process your message here
        # Your submitted data is in msg.body
        if $stomp.connected? && !ignore_disconnect
          # do nothing, we're going down
        else
          handle(message)
>>>>>>> Stashed changes
        end
      end

    def stop
      RuoteStomp.stop!
    end

    # (feel free to overwrite me)
    #
    def decode_workitem(msg)
      (Rufus::Json.decode(msg) rescue nil)
    end

    private

    def handle(msg)
      item = decode_workitem(msg.body)
      return unless item.is_a?(Hash)
<<<<<<< Updated upstream
      not_li = ! item.has_key?('definition')      
=======
      not_li = ! item.has_key?('definition')
>>>>>>> Stashed changes
      return if @launchitems == :only && not_li
      return unless @launchitems || not_li

      if not_li
        receive(item) # workitem resumes in its process instance
      else
        launch(item) # new process instance launch
      end

    rescue => e
      # something went wrong
      # let's simply discard the message
      $stderr.puts('=' * 80)
      $stderr.puts(self.class.name)
      $stderr.puts("couldn't handle incoming message :")
      $stderr.puts('')
      $stderr.puts(msg.inspect)
      $stderr.puts('')
      $stderr.puts(Rufus::Json.pretty_encode(item)) rescue nil
      $stderr.puts('')
      $stderr.puts(e.inspect)
      $stderr.puts(e.backtrace)
      $stderr.puts('=' * 80)
    end

    def launch(hash)
      super(hash['definition'], hash['fields'] || {}, hash['variables'] || {})
    end
  end
end