# encoding: utf-8
module Core
  module Parser
    module UXF
      include Core::Shapes

      def parse path
        doc = Nokogiri::XML(File.open path)

        puts "Parsing learning case from UXF file " + path + "\n"

        puts "Getting initial state..."
        @initial_state = nil
        rect = (parse_basic_rectangle_element doc, 'com.umlet.element.custom.InitialState').first
        @initial_state = Core::Evaluator::LearningCaseComponents::InitialState.new rect
        puts "Initial state found." unless @initial_state.nil?

        puts "Getting final state..."
        final_state = nil
        rect = (parse_basic_rectangle_element doc, 'com.umlet.element.custom.FinalState').first
        final_state = Core::Evaluator::LearningCaseComponents::FinalState.new rect
        puts "Final state found." unless final_state.nil?

        puts "Getting states..."
        states = []
        doc.xpath('//element[type = \'com.umlet.element.custom.State\']').each do |node|
          position = Vector2.new Integer(node.css('x').first.text), Integer(node.css('y').first.text)
          size = Vector2.new Integer(node.css('w').first.text), Integer(node.css('h').first.text)
          rect = Rectangle.new position, size
          details = node.css('panel_attributes').first.text.split(' ')
          details[0] = details[0].to_sym
          states.append Core::Evaluator::LearningCaseComponents::State.new Core::Evaluator::EventPrescription.new(details), rect
        end
        puts "Found "+states.length.to_s+" states."

        puts "Getting decision nodes..."
        decisions = []
        (parse_basic_rectangle_element doc, 'com.umlet.element.custom.Decision').each do |rect|
          decisions.append Core::Evaluator::LearningCaseComponents::Decision.new rect
        end
        puts "Found " + decisions.length.to_s + " decision nodes."

        puts "Getting branch nodes..."
        branches = []
        (parse_basic_rectangle_element doc, 'com.umlet.element.custom.SynchBarVertical\' or type = \'com.umlet.element.custom.SynchBarHorizontal').each do |rect|
          branches.append Core::Evaluator::LearningCaseComponents::Branch.new rect
        end
        puts "Found " + branches.length.to_s  + " branch nodes."

        puts "Getting relations..."
        relations = []
        doc.xpath('//element[type = \'com.umlet.element.Relation\']').each do |node|
          position = Vector2.new Integer(node.css('x').first.text) + 30, Integer(node.css('y').first.text) + 30
          size = Vector2.new Integer(node.css('w').first.text) - 50, Integer(node.css('h').first.text) - 50

          upper_left_point = position
          upper_right_point = Vector2.new position.x + size.x, position.y
          lower_left_point = Vector2.new position.x, position.y + size.y
          lower_right_point = Vector2.new position.x + size.x, position.y + + size.y

          start_point, end_point = nil
          disjoint_directions = node.css('additional_attributes').first.text.split(';').collect { |str| Integer(str)}
          right = 0
          down = 1
          left = 2
          up = 3
          if disjoint_directions[right] >= disjoint_directions[left]
            if disjoint_directions[down] >= disjoint_directions[up]
              start_point = upper_left_point
              end_point = lower_right_point
            else
              start_point = lower_left_point
              end_point = upper_right_point
            end
          else
            if disjoint_directions[down] >= disjoint_directions[up]
              start_point = upper_right_point
              end_point = lower_left_point
            else
              start_point = lower_right_point
              end_point = upper_left_point
            end
          end

          relations.append Core::Evaluator::LearningCaseComponents::OrientedRelation.new start_point, end_point
        end
        puts "Found " + relations.length.to_s + " relations."

        connect_activity_nodes [@initial_state, final_state] + states + decisions + branches, relations

      end

      def parse_basic_rectangle_element doc, name
        rects = Array.new
        doc.xpath("//element[type = \'#{name}\']").each do |node|
          position = Vector2.new Integer(node.css('x').first.text), Integer(node.css('y').first.text)
          size = Vector2.new Integer(node.css('w').first.text), Integer(node.css('h').first.text)
          rects.append Rectangle.new position, size
        end

        rects
      end



      def connect_activity_nodes nodes, relations
        puts "Connecting activity nodes..."
        relations.each do |relation|
          entry_node, exit_node = nil
          nodes.each do |node|
            break unless entry_node.nil? || exit_node.nil?
            if node.is_entry_node_of relation
              entry_node = node
              next
            end
            if node.is_exit_node_of relation
              exit_node = node
              next
            end
          end
          unless entry_node.nil? && exit_node.nil?
            entry_node.add_next_node exit_node
            exit_node.add_previous_node entry_node
          end
        end
        puts "Activity nodes connected."
      end

    end
  end
end
