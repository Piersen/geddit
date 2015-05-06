module Core
  module Evaluator
    class EventOpCounter

      def initialize event, additions = 0, transposition = 0
        @event = event
        @additions = additions
        @transpositions = transposition
      end

      attr_accessor :event, :additions, :transpositions
    end

  end
end