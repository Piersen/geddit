module Core
  module Evaluator
    module LearningCaseComponents

      class OrientedRelation

        def initialize start_point, end_point
          @start_point = start_point
          @end_point = end_point
        end


        def to_s
          'Relation: Start: ' + @start_point.to_s + ' End: ' + @end_point.to_s
        end

        attr_accessor :start_point, :end_point
      end
    end
  end
end

