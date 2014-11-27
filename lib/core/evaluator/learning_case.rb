module Core
  module Evaluator
    class LearningCase
      include Core::Parser::UXF

      @initial_state

      def initialize path
        parse path
      end

      def match interaction_events

      end


    end
  end
end
