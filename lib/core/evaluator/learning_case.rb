module Core
  module Evaluator
    class LearningCase
      include Core::Parser::UXF

      def initialize path
        doc = parse path
        print doc
      end

      def match interaction_events

      end


    end
  end
end
