module Core
  module Evaluator
    class EventOpCounter

      def initialize event, additions_before
        @event = event
        @additions_before = additions_before
      end

      attr_accessor :event, :additions_before
    end

  end
end