module Core
  module Evaluator
    module LearningCaseComponents
      class State
        include Core::Evaluator::LearningCaseComponents::ActivityNode

        def initialize content, position
          @content = content
          after_initialize position
        end

        attr_accessor :content
      end
    end
  end
end

