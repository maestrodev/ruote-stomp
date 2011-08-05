require 'ruote/part/local_participant'
require 'ruote-stomp'

module RuoteStomp
  #
  # = Stomp Participants
  #
  # The RuoteStomp::ParticipantProxy allows you to send workitems (serialized as
  # JSON) or messages to any Stomp queues right from the process
  # definition. When combined with the RuoteStomp::Receiver you can easily
  # leverage an extremely powerful local/remote participant
  # combinations.
  #
  # For local/remote participants The local part of the
  # RuoteStomp::ParticipantProxy relies on the presence of a
  # RuoteStomp::Receiver. Workitems are sent to the remote participant
  # and the local part does not normally reply to the engine.  Instead
  # the engine will continue when a reply is received on the
  # 'ruote_workitems' queue (see RuoteStomp::Receiver).
  #
  # Of course, the standard :forget => true format can be used even
  # with remote particpants and :forget can even be set as a default in
  # the options.
  #
  # [NOTE: Working this port next!!!]
  # A simple way to create a remote participant to act upon workitems
  # is to use the daemon-kit ruote responder.
  #
  # Simple Stomp messages are treated as 'fire and forget' and the flow
  # will continue when the local participant has queued the message
  # for sending. (As there is no meaningful way to receive a workitem
  # in reply).
  #
  # == Configuration
  #
  # Stomp configuration is handled by directly manipulating the
  # values of the +Stomp.settings+ hash, as provided by the Stomp
  # gem. No Stomp defaults are set by the participant.
  #
  # == Usage
  #
  # Define the queue used by an AMQP participant :
  #
  #   engine.register_participant(
  #     :delete_user, RuoteStomp::ParticipantProxy, 'queue' => 'user_manager')
  #
  # Sending a workitem to the remote participant defined above:
  #
  #   Ruote.process_definition do
  #     sequence do
  #       delete_user
  #     end
  #   end
  #
  # Let the local participant reply to the engine without involving
  # the receiver
  #
  #   Ruote.process_definition do
  #     sequence do
  #       delete_user :forget => true
  #     end
  #   end
  #
  # Setting up the participant in a slightly more 'raw' way:
  #
  #   engine.register_participant(
  #     :stomp, RuoteStomp::ParticipantProxy )
  #
  # Sending a workitem to a specific queue:
  #
  #   Ruote.process_definition do
  #     sequence do
  #       stomp :queue => 'test', 'command' => '/run/regression_test'
  #     end
  #   end
  #
  # Setup a 'fire and forget' participant that always replies to the
  # engine:
  #
  #   engine.register_participant(
  #     :jfdi, RuoteStomp::ParticipantProxy, 'forget' => true )
  #
  # Sending a message example to a specific queue (both steps are
  # equivalent):
  #
  #   Ruote.process_definition do
  #     sequence do
  #       stomp :queue => 'test', :message => 'foo'
  #       stomp :queue => 'test', :message => 'foo', :forget => true
  #     end
  #   end
  #
  #
  # == Stomp notes
  #
  # The direct exchanges are always marked as durable by the
  # participant, and messages are marked as persistent by default (see
  # #RuoteStomp)
  #
  class ParticipantProxy

    include Ruote::LocalParticipant

    # The following parameters are used in the process definition.
    #
    # An options hash with the same keys to provide defaults is
    # accepted at registration time (see above).
    #
    # * :queue => (string) The Stomp queue used by the remote participant.
    #   nil by default.
    # * :forget => (bool) Whether the flow should block until the remote
    #   participant replies.
    #   false by default
    #
    def initialize(options)
      @options = {
        'queue' => nil,
        'forget' => false,
      }.merge(options.inject({}) { |h, (k, v)|
        h[k.to_s] = v; h
      })
      #
      # the inject is here to make sure that all options have String keys
    end

    # Process the workitem at hand. By default the workitem will be
    # published to the direct exchange specified in the +queue+
    # workitem parameter. You can specify a +message+ workitem
    # parameter to have that sent instead of the workitem.
    #
    def consume(workitem)

      RuoteStomp.start!
      target_queue = determine_queue(workitem)

      raise 'no queue specified (outbound delivery)' unless target_queue

      forget = determine_forget(workitem)

      opts = {
        :persistent => RuoteStomp.use_persistent_messages?,
        :content_type => 'application/json' }

      if message = workitem.fields['message'] || workitem.params['message']

        forget = true # sending a message implies 'forget' => true
        $stomp.publish target_queue, message, opts         
      else
        $stomp.publish target_queue, encode_workitem(workitem), opts
      end

      reply_to_engine(workitem) if forget
    end

    # (Stops the underlying queue subscription)
    #
    def stop
      RuoteStomp.stop!
    end

    def cancel(fei, flavour)
      #
      # TODO : sending a cancel item is not a bad idea, especially if the
      #        job done over the stomp fence lasts...
      #
    end

    # [NOT sure about this behavior with Stomp yet.  Need to dive.]
    
    def do_not_thread
      true
    end

    private

    def determine_forget(workitem)
      return workitem.params['forget'] if workitem.params.has_key?('forget')
      return @options['forget'] if @options.has_key?('forget')
      false
    end

    def determine_queue(workitem)
      workitem.params['queue'] || @options['queue']
    end

    # Encodes the workitem as JSON. Makes sure to add to the field 'params'
    # an entry named 'participant_options' which contains the options of
    # this participant.
    #
    def encode_workitem(wi)
      wi.params['participant_options'] = @options
      Rufus::Json.encode(wi.to_h)
    end
  end

  #
  # Kept for backward compatibility.
  #
  # You should use RuoteStomp::ParticipantProxy.
  #
  class Participant < ParticipantProxy

    def initialize(options)
      puts '=' * 80
      puts "RuoteStomp::Participant will be deprecated soon (2.1.12)"
      puts "please use RuoteStomp::ParticipantProxy instead"
      puts '=' * 80
      super
    end
  end
end

