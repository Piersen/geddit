module Core
  module Evaluator
    class LearningCase
      include Core::Parser::UXF

      @initial_state
      @possible_passes

      attr_accessor :possible_passes

      def initialize path
        case File.extname(path)
          when '.uxf'
            parse path
            @possible_passes = generate_possible_passes @initial_state
          when '.csv'
            File.open(path, "rb:UTF-8") do |f|
              @possible_passes = f.map{|line| line.chomp.split(',').map{|event| details = event.split(' '); details[0] = details[0].to_sym; EventPrescription.new(details)}}
            end
        end
      end

      def save path
        File.open(path, "w:UTF-8") do |f|
          @possible_passes.each do |pass|
            f.puts pass.map{|event| event.to_s }.join ','
          end
        end
      end

      def evaluate events

        bestpass = nil

        # Evaluate each of the possible passes
        @possible_passes.each_with_index do |pass, pass_index|
          params = Set.new

          # Find all parameters in event prescriptions
          pass.each do |prescription|
            prescription.members.each do |member|
              parameter_cut = InteractionEvent.parameter_cut member
              if parameter_cut.length != 1
                params.add parameter_cut[1]
              end
            end
          end

          # Create a dictionary for parameter values
          all_param_dict = Hash.new
          params.each do |param|
            all_param_dict[param] = [nil].to_set
          end

          # Pure list contains all events that match any of the prescriptions
          # Irrelevant previous events are counted in event operation counter
          pure_list = Array.new

          # Make a pure list of interesting events, collect all possible parameter values
          addition_count = 0
          events.each do |event|
            was_matched = false
            pass.each do |prescription|
              if event.matches(prescription)
                pure_list << EventOpCounter.new(event, addition_count) if !was_matched
                was_matched = true
                addition_count = 0
                event.parameter_dictionary.each do |key, value|
                  if(all_param_dict[key].count == 1 && all_param_dict[key].to_a[0] == nil) # replace the default nil containing set
                    all_param_dict[key] = Set.new
                  end
                  all_param_dict[key].add value
                end
              end
            end
            if !was_matched
              addition_count += 1
            end
          end


          # Get all combinations of parameter values
          param_combinations = all_param_dict.first[1].to_a.product *all_param_dict.drop(1).map {|hash| hash[1].to_a}

          # Find param combinations with least amount of deletions
          first_run = true
          min_deletions = 0
          best_param_dicts = Array.new
          param_combinations.each do |param_combo|
            param_dict = param_combo_to_dict param_combo, all_param_dict

            # Mark all prescriptions as not yet found
            pass.each do |prescription|
              prescription.found_in_event_data = false
            end

            # Calculate matches using the parameter dictionary
            pure_list.each do |event_op_counter|
              pass.each do |prescription|
                if event_op_counter.event.equals prescription, param_dict
                  prescription.found_in_event_data = true
                end
              end
            end

            # Count deletions and adjust the best parameter dictionaries if necessary
            deletions = 0
            pass.each do |prescription|
              if !prescription.found_in_event_data
                deletions += 1
              end
            end
            if !first_run && deletions < min_deletions
              best_param_dicts = Array.new
            end
            if first_run || deletions <= min_deletions
              best_param_dicts << param_dict
              first_run = false
              min_deletions = deletions
            end
          end

          # Find evaluated paths with the least transpositions and additions for all of the best param dictionaries
          best_param_dicts.each do |param_dict|
            # A structure for storing all positions of events equal to the prescription
            position_list = Array.new(pass.count) { Array.new }
            # A structure for storing fixed paths without transpositions, from which the best one is the chosen
            fixed_paths = [ GreedyFixedPath.new ]

            # Calculate the fixed paths
            pure_list.each_with_index do |event_op_counter, pure_list_index|
              pass.each_with_index do |prescription, prescription_index|
                if event_op_counter.event.equals prescription, param_dict

                  # For each path, append if it can be appended, if the append requires a jump over, branch into a new path
                  new_branches = Array.new
                  fixed_paths.each do |fixed_path|
                    branch = fixed_path.append_event_counter_or_branch event_op_counter, prescription_index, pure_list_index
                    if !branch.nil?
                      new_branches << branch
                    end
                  end
                  fixed_paths += new_branches

                  position_list[prescription_index] << pure_list_index
                end
              end
            end

            # Select only the fixed paths with the least amount of transpositions
            best_fixed_paths = []
            fixed_paths.each do |fixed_path|
              if !best_fixed_paths.empty? && fixed_path.success_rating > best_fixed_paths.first.success_rating
                best_fixed_paths = []
              end
              if best_fixed_paths.empty? || fixed_path.success_rating == best_fixed_paths.first.success_rating
                best_fixed_paths << fixed_path
              end
            end

            # Create path evaluations by calculating transpositions for each fixed path, and calculating additions in pure path
            best_evaluated_paths_for_dict = Array.new
            best_fixed_paths.each do |fixed_path|
              evaluated = EvaluatedPath.new pass, param_dict
              event_positions = Array.new(pass.count, -1)
              event_transpositions = Array.new(pass.count, 0)

              # Set all fixed event positions according to the position they were found in
              fixed_path.fixed_event_positions.each_with_index do |position, i|
                event_positions[position] = fixed_path.indices[i]
              end

              # Find closest position of unfixed events and calculate transpositions
              new_positions = Array.new(event_positions)
              event_positions.each_with_index do |position, i|
                if position == -1 && position_list[i].count != 0
                  replacement_index = 0
                  separator = 0
                  best_replacement_index = replacement_index
                  best_separator = separator
                  found_separator_left = false
                  while replacement_index < position_list[i].count && separator < event_positions.count
                    if event_positions[separator] == position_list[i][replacement_index]
                      replacement_index += 1
                      next
                    end
                    if event_positions[separator] != -1
                      if separator < i
                        if event_positions[separator] < position_list[i][replacement_index]
                          separator += 1
                        elsif event_positions[separator] > position_list[i][replacement_index]
                          best_replacement_index = replacement_index
                          best_separator = separator
                          found_separator_left = true
                          replacement_index += 1
                        end
                      elsif separator > i
                        if event_positions[separator] < position_list[i][replacement_index]
                          separator += 1
                          if found_separator_left && (separator - i) > (i - best_separator)
                            break
                          end
                        elsif event_positions[separator] > position_list[i][replacement_index]
                          best_replacement_index = replacement_index
                          best_separator = separator - 1
                          break;
                        end
                      end
                    else
                      separator += 1
                    end
                  end
                  if !found_separator_left
                    best_replacement_index = replacement_index
                    best_separator = separator - 1
                  end
                  new_positions[i] = position_list[i][best_replacement_index]
                  event_transpositions[i] = (best_separator - i)
                end
              end

              event_positions = new_positions


              #Calculate additions and generate the finalised evaluated path
              sorted_position_indices = event_positions.map.with_index.sort.map(&:last)
              addition_count = 0
              index_pointer = 0
              while event_positions[sorted_position_indices[index_pointer]] == -1 && index_pointer < sorted_position_indices.count
                index_pointer += 1
              end
              pure_list.each_with_index do |event_op_counter, position|
                if index_pointer == sorted_position_indices.count
                  break
                end
                if position == event_positions[sorted_position_indices[index_pointer]]
                  evaluated.event_op_counters[sorted_position_indices[index_pointer]] = EventOpCounter.new event_op_counter.event, addition_count + event_op_counter.additions, event_transpositions[sorted_position_indices[index_pointer]]
                  if evaluated.first_event_index == -1
                    evaluated.first_event_index = sorted_position_indices[index_pointer]
                  end
                  addition_count = 0
                  index_pointer += 1
                else
                  addition_count += event_op_counter.additions + 1 # the count of additions for that event + the event itself
                end
              end

              # Adjust the evaluated paths array to only contain the paths with best fitness
              if !best_evaluated_paths_for_dict.empty? && evaluated > best_evaluated_paths_for_dict.first
                best_evaluated_paths_for_dict = Array.new
              end
              if best_evaluated_paths_for_dict.empty? || evaluated == best_evaluated_paths_for_dict.first
                best_evaluated_paths_for_dict << evaluated
              end
            end

          end

        end

      end

      private

      def param_combo_to_dict combo, all_param_dict
        val = Hash.new

        all_param_dict.each_with_index do |param_value, index|
          val[param_value[0]] = combo[index]
        end

        val
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
