module Core
  module Evaluator
    class EvaluatedPath

      def initialize event_prescriptions, param_dictionary
        @event_prescriptions = event_prescriptions
        @param_dictionary = param_dictionary
        @event_op_counters = Array.new event_prescriptions.count
      end

      def <=>(another)
        #if self.size < another_sock.size
        #  -1
        #elsif self.size > another_sock.size
        #  1
        #else
        #  0
        #end
      end

      attr_accessor :event_prescriptions, :param_dictionary, :event_op_counters
    end
  end
end