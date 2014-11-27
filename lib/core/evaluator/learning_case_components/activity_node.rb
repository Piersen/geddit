module Core
  module Evaluator
    module LearningCaseComponents
      module ActivityNode

        attr_accessor :frame

        def after_initialize frame
          @frame = frame
          @previous_nodes = []
          @next_nodes = []
        end

        def add_previous_node node
          @previous_nodes[0] = node
        end

        def add_next_node node
          @next_nodes[0] = node
        end

        def next
          @next_nodes[0]
        end

        def is_block_start
          @next_nodes.length > 1
        end

        def is_block_end
          @previous_nodes.length > 1
        end

        def is_entry_node_of relation
          return true if @frame.contains relation.start_point
          false
        end

        def is_exit_node_of relation
          return true if @frame.contains relation.end_point
          false
        end

        def to_s
          self.class.to_s + ' - ' + @frame.to_s
        end

        attr_accessor :next_nodes

      end
    end
  end
end
