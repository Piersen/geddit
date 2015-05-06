module Core
  module Evaluator
    class EvaluatedPath
      include Comparable

      def initialize event_prescriptions, param_dictionary
        @event_prescriptions = event_prescriptions
        @param_dictionary = param_dictionary
        @event_op_counters = Array.new event_prescriptions.count
        @first_event_index = -1
      end

      def deletions
        event_op_counters.count nil
      end

      def transpositions
        val = 0
        event_op_counters.each do |c|
          if !c.nil?
            val += c.transpositions.abs
          end
        end
        val
      end

      def additions
        val = 0
        event_op_counters.each_with_index do |c, index|
          if !c.nil? && index != first_event_index
            val += c.additions
          end
        end
        val
      end

      def to_s
        "Evaluated path:\nDeletions: #{deletions} Transpositions: #{transpositions} Additions: #{additions}\nPath prescription: #{@event_prescriptions.to_s}\nDictionary: #{@param_dictionary.to_s}\nEvents: #{events.to_s}\nEvent Ts: #{transposition_array.to_s}\nEvent As: #{addition_array.to_s} (#{@first_event_index}. indexed event was first and does not count to overall additions)\n"
      end

      def <=>(another)
        if self.deletions < another.deletions
          return 1
        elsif self.deletions > another.deletions
          return -1
        else
          if self.transpositions < another.transpositions
            return 1
          elsif self.transpositions > another.transpositions
            return -1
          else
            if self.additions < another.additions
              return 1
            elsif self.additions > another.additions
              return -1
            else
              return 0
            end
          end
        end
      end

      def events
        val = @event_op_counters.map { |c|
          if c.nil?
            nil
          else
          c.event
          end
        }
      end

      def transposition_array
        val = @event_op_counters.map { |c|
          if c.nil?
            nil
          else
            c.transpositions
          end
        }
      end

      def addition_array
        val = @event_op_counters.map { |c|
          if c.nil?
            nil
          else
            c.additions
          end
        }
      end

      attr_accessor :event_prescriptions, :param_dictionary, :event_op_counters, :first_event_index
    end
  end
end