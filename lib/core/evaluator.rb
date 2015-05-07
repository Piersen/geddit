require 'core/evaluator/event_prescription'
require 'core/evaluator/event_op_counter'
require 'core/evaluator/greedy_fixed_path'
require 'core/evaluator/evaluated_path'
require 'core/evaluator/learning_case'
require 'core/evaluator/interaction_event'
require 'core/evaluator/learning_case_components'

module Core
  module Evaluator

    def self.evaluate_learning_case learning_case_path, interaction_events_path
      learning_case = Core::Evaluator::LearningCase.new learning_case_path
      events = Core::Evaluator::InteractionEvent.load_all interaction_events_path
      best_paths = learning_case.evaluate events
    end

    def self.mass_evaluate_learning_cases path
      learning_cases_root = path + "\\learningcases\\processed"
      data_root = path + "\\data\\processed"
      output_root = path + "\\output"

      games = Dir.entries(learning_cases_root).select {|entry| File.directory?(learning_cases_root+"\\"+entry) and !(entry =='.' || entry == '..') }

      games.each do |game|
        puts "Game: " + game

        game_lc_folder = learning_cases_root + "\\" + game
        game_data_folder = data_root + "\\" + game
        game_out_folder = output_root + "\\" + game

        learning_case_files = Dir.entries(game_lc_folder).select {|entry| !(entry =='.' || entry == '..') }
        learning_case_files.each do |learning_case_file|

          output_file = File.open(game_out_folder+"\\"+learning_case_file.split('.')[0]+"_results.txt", "w:UTF-8")

          learning_case = Core::Evaluator::LearningCase.new game_lc_folder + "\\" + learning_case_file

          event_files = Dir.entries(game_data_folder).select {|entry| !(entry =='.' || entry == '..') }
          event_files.each do |event_file|
            events = Core::Evaluator::InteractionEvent.load_all game_data_folder + "\\" + event_file
            best_paths = learning_case.evaluate events

            output_file.puts event_file.split('.')[0]
            output_file.puts best_paths.to_s
          end

          output_file.close

        end

      end
    end

  end
end