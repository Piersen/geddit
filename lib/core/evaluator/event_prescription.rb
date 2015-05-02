module Core
  module Evaluator
    class EventPrescription

      def initialize details
        @type = details[0]
        @id = details[1]
        @other = details.drop 2
      end

      def match interaction_event, param_dictionary

      end

      def to_s
        [@type, @id, @other].join(' ')
      end

      def members
        [@id].concat @other
      end

      attr_accessor :type, :id, :other, :found_in_event_data
    end
  end
end