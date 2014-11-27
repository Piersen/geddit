module Core
  module Evaluator
    module LearningCaseComponents
      class FinalState
        include Core::Evaluator::LearningCaseComponents::ActivityNode

        def initialize position
          after_initialize position
        end

        def is_block_end
          true
        end

      end
    end
  end
end
