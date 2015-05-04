module Core
  module Evaluator
    class EventOpCounter

      def initialize event, additions = 0
        @event = event
        @additions = additions
        @transpositions = 0
      end

      attr_accessor :event, :additions, :transpositions
    end

  end
end