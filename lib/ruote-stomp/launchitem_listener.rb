
module RuoteStomp

  #
  # Got replaced by RuoteStomp::Receiver
  #
  # This class is kept for backward compatibility.
  #
  class LaunchitemListener < ::RuoteStomp::Receiver

    # Start a new LaunchItem listener
    #
    # @param [ Ruote::Engine, Ruote::Storage ] A configured ruote engine or storage instance
    # @param opts :queue / :unsubscribe
    #
    def initialize(engine_or_storage, opts={})

      super(engine_or_storage, opts.merge(:launchitems => :only))
    end
  end
end

