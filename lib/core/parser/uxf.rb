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
          states.append Core::Evaluator::LearningCaseComponents::State.new node.css('panel_attributes').first.text, rect
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

        @action_strings = generate_possible_passes @initial_state
      end

      def save path
        File.open(path, "w:UTF-8") do |f|
          @action_strings.each do |action_string|
            f.puts action_string.join ','
          end
        end
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



      def generate_possible_passes start_node
        block_passes = Array.new
        if start_node == @initial_state
          puts 'Transforming learning case into strings'
        end

        routes = Array.new
        start_node.next_nodes.each do |route_start|
          route_passes = Array.new [Array.new]
          pass_node = route_start
          until pass_node.is_block_end
            if pass_node.is_block_start
              subblock_passes = generate_possible_passes pass_node
              new_route_passes = Array.new
              route_passes.each do |route_pass|
                subblock_passes.each do |subblock_pass|
                  STDOUT.flush
                  new_route_passes.append route_pass.dup.concat(subblock_pass)
                end
              end
              route_passes = new_route_passes
              pass_node = (get_corresponding_block_end pass_node).next
            else
              route_passes.each do |route_pass|
                route_pass.append pass_node.content
              end
              pass_node = pass_node.next
            end
          end
          routes.append route_passes
        end

        if (start_node.class.name.split('::').last || '') == 'Branch'
          routes = branches_to_alternatives routes
        end

        routes.each do |route|
          route.each do |route_pass|
            block_passes.append route_pass
          end
        end

        if start_node == @initial_state
          puts 'Learning case transformation complete'
        end

        block_passes
      end

      def get_corresponding_block_end block_start
        node = block_start
        level = 0
        loop do
          if node.is_block_start
            level += 1
          end
          if node.is_block_end
            level -= 1
          end
          break if level <= 0
          node = node.next
        end
        node
      end



      def branches_to_alternatives branched_routes
        route_variant_combinations = Array (0..branched_routes[0].length-1)
        branched_routes.drop(1).each do |route|
          route_variant_combinations = route_variant_combinations.product(Array (0..route.length-1))
        end

        alternatives = Array.new
        route_variant_combinations.each do |route_combo|
          alternative_length = 0
          route_variants = Array.new
          branched_routes.each_with_index do |route, i|
            route_variant = route[route_combo[i]]
            route_variants.append route_variant
            alternative_length += route_variant.length
          end

          unoccupied_positions = Array (0..alternative_length-1)
          add_alternatives 0, unoccupied_positions, alternative_length, route_variants, Array.new, alternatives

        end

        [alternatives]
      end



      def add_alternatives depth, unoccupied_positions, alternative_length, route_variants, variants_occupations, alternatives
        possible_occupations = (unoccupied_positions.combination route_variants[depth].length).to_a

        possible_occupations.each do |occupation|
          if(depth < route_variants.length - 1)
            add_alternatives depth+1, unoccupied_positions - occupation, alternative_length, route_variants, variants_occupations + [occupation], alternatives
          else
            alternative = Array.new alternative_length, ''
            insertion_indexes = Array.new depth+8, 0
            (variants_occupations + [occupation]).each_with_index do |variant_occupation, i|
              variant_occupation.each do |position|
                alternative[position] = route_variants[i][insertion_indexes[i]]
                insertion_indexes[i] += 1
              end
            end
            alternatives.append alternative
          end
        end
      end



    end
  end
end
