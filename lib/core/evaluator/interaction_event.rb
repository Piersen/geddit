module Core
  module Evaluator
    EVENT_TYPES = [ :input, :gaze, :custom ]
    class InteractionEvent

      def initialize event_type, timestamp
        @event_type = event_type
        @timestamp = timestamp
      end

    end
  end
end