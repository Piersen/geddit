module Core
  module Evaluator
    class GreedyFixedPath

      def initialize parent = nil, jump_event_counter = nil, jump_position = 0, index = 0
        if !parent.nil?
          @fixed_event_counters = Array.new parent.fixed_event_counters
          @fixed_event_positions = Array.new parent.fixed_event_positions
          @indices = Array.new parent.indices
        else
          @fixed_event_counters = Array.new
          @fixed_event_positions = Array.new
          @indices = Array.new
        end

        if !jump_event_counter.nil?
          @fixed_event_counters << jump_event_counter
          @fixed_event_positions << jump_position
          @indices << index
        end
      end

      def append_event_counter_or_branch jump_event_counter, jump_position, index
        if (@fixed_event_positions.empty? && jump_position == 0) || (!@fixed_event_positions.empty? && jump_position == @fixed_event_positions.last + 1)
          @fixed_event_counters << jump_event_counter
          @fixed_event_positions << jump_position
          @indices << index
          return nil
        end
        if @fixed_event_positions.empty? || (!@fixed_event_positions.empty? && jump_position > @fixed_event_positions.last + 1)
          return GreedyFixedPath.new self, jump_event_counter, jump_position, index
        end
        return nil
      end

      def success_rating
        return @fixed_event_positions.count
      end


      attr_accessor :fixed_event_counters, :fixed_event_positions, :indices
    end
  end
end