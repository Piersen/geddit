module Core
  module Evaluator
    module LearningCaseComponents
      class InitialState
        include Core::Evaluator::LearningCaseComponents::ActivityNode

        def initialize position
          after_initialize position
        end

      end
    end
  end
end
