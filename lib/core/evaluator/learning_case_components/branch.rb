module Core
  module Evaluator
    module LearningCaseComponents
      class Branch
        include Core::Evaluator::LearningCaseComponents::ActivityNode

        def initialize position
          after_initialize position
        end

        def add_previous_node node
          @previous_nodes.append node
        end

        def add_next_node node
          @next_nodes.append node
        end

      end
    end
  end
end
