require 'core/preprocessor/interface_object'
require 'pathname'

module Core
  module Preprocessor
    include Core::Shapes

    def self.process_usage_events gaze_data_path, gui_change_log_path, custom_event_log_path, output_path

      time_format = '%FT%T.%L'
      gaze_tolerance = 20

      interface_objects = Hash.new

      custom_event_doc = File.open(custom_event_log_path, "r:UTF-8")
      custom_event_line = safe_csv_readline custom_event_doc

      gaze_data_doc = File.open(gaze_data_path, "r:UTF-8")
      gaze_data_doc.readline
      gaze_data_line = safe_csv_readline gaze_data_doc

      gui_change_doc = File.open(gui_change_log_path, "r:UTF-8")
      gui_change_line = safe_csv_readline gui_change_doc

      output_file = File.open(output_path, "w:UTF-8")

      current_fixation_id = 0
      current_fixation_seen_objects = Array.new


      until custom_event_line.nil? && gaze_data_line.nil? && gui_change_line.nil?

        custom_event_date = custom_event_line.nil? ? nil : (DateTime.parse custom_event_line[1][0..-7])
        if gui_change_line.nil?
          gui_change_date = nil
        else
          if gui_change_line[0] != 'End'
            gui_change_date = (DateTime.parse gui_change_line[6][0..-7])
          else
            gui_change_date = (DateTime.parse gui_change_line[2][0..-7])
          end
        end
        gaze_sample_date = gaze_data_line.nil? ? nil : (DateTime.parse (gaze_data_line[6].split('. ').reverse.map{ |d| d.rjust(2,'0') }.join('-')+"T"+gaze_data_line[24]+'0000'))

        min_time = [ custom_event_date, gaze_sample_date, gui_change_date ].compact.min
        if min_time == custom_event_date
          output_file.puts ([ 'CUSTOM', custom_event_line[0], custom_event_date.strftime(time_format) ] + custom_event_line[2..-1]).join ','
          custom_event_line = safe_csv_readline custom_event_doc
        end
        if min_time == gaze_sample_date

          #Handle mouse inputs
          unless gaze_data_line[27].empty?
            click_point = Vector2.new Integer(gaze_data_line[28]), Integer(gaze_data_line[29])
            clicked_object = false
            interface_objects.each do |name, obj|
              if obj.rect.contains click_point
                output_file.puts ([ 'INPUT', 'Mouse'+gaze_data_line[27], gaze_sample_date.strftime(time_format), name, obj.params ] ).join ','
                clicked_object = true
              end
            end
            unless clicked_object
              output_file.puts ([ 'INPUT', 'Mouse'+gaze_data_line[27], gaze_sample_date.strftime(time_format), 'UNKNOWN', click_point.x.to_s, click_point.y.to_s ] ).join ','
            end
          end

          #Handle key inputs
          output_file.puts ([ 'INPUT', gaze_data_line[33], gaze_sample_date.strftime(time_format) ] ).join ',' unless gaze_data_line[33].empty? || gaze_data_line[33] == 'None'

          #Handle gaze fixations
          if(gaze_data_line[43] == 'Fixation')

            unless Integer(gaze_data_line[41]) == current_fixation_id
              current_fixation_id = Integer(gaze_data_line[41])
              current_fixation_seen_objects = Array.new
            end

            unless gaze_data_line[52].empty? ||  gaze_data_line[53].empty?
              gaze_point = Vector2.new(Integer(gaze_data_line[52]), Integer(gaze_data_line[53]))

              interface_objects.each do |name, obj|
                if obj.rect.is_in_proximity(gaze_tolerance, gaze_point) && !current_fixation_seen_objects.include?(name)
                  output_file.puts ([ 'GAZE', name, gaze_sample_date.strftime(time_format), obj.params ] ).join ','
                  current_fixation_seen_objects.append name
                end
              end
            end

          end

          gaze_data_line = safe_csv_readline gaze_data_doc
        end
        if min_time == gui_change_date
          case gui_change_line[0]
            when 'Begin'
              interface_objects[gui_change_line[1]] = InterfaceObject.new(Rectangle.new(Vector2.new(Integer(gui_change_line[2]), Integer(gui_change_line[3])), Vector2.new(Integer(gui_change_line[4]), Integer(gui_change_line[5]))), gui_change_line.drop(7))
            when 'Change'
              interface_objects[gui_change_line[1]].rect = Rectangle.new(Vector2.new(Integer(gui_change_line[2]), Integer(gui_change_line[3])), Vector2.new(Integer(gui_change_line[4]), Integer(gui_change_line[5])))
            when 'End'
              interface_objects.delete gui_change_line[1]
          end
          gui_change_line = safe_csv_readline gui_change_doc
        end


      end

      custom_event_doc.close
      gui_change_doc.close
      gaze_data_doc.close
      output_file.close

    end

    def self.mass_process_usage_events path
      raw_data_root = path+"\\data\\raw"
      output_root = path+"\\data\\processed"

      participants = Dir.entries(raw_data_root).select {|entry| File.directory?(raw_data_root+"\\"+entry) and !(entry =='.' || entry == '..') }

      participants.each do |participant|
        puts "Processing participant: " + participant
        partipant_folder = raw_data_root + "\\" + participant

        games = Dir.entries(partipant_folder).select {|entry| File.directory?(partipant_folder+"\\"+entry) and !(entry =='.' || entry == '..') }

        games.each do |game|
          puts "Processing game: " + game
          game_input_folder = partipant_folder + "\\" + game
          game_output_folder = output_root + "\\" + game

          gaze_data_path = game_input_folder + "\\GazeTrackingData.csv"
          gui_change_log_path = game_input_folder + "\\GuiChangeLog.dat"
          custom_event_log_path = game_input_folder + "\\CustomEventLog.dat"
          output_path = game_output_folder + "\\" + participant + ".csv"

          process_usage_events gaze_data_path, gui_change_log_path, custom_event_log_path, output_path
        end

      end
    end

    def self.process_learning_case uxf_path, output_path
      lc = Core::Evaluator::LearningCase.new uxf_path
      lc.save output_path
    end

    def self.mass_process_learning_cases path
      root = path + "\\learningcases\\uxf"

      games = Dir.entries(root).select {|entry| File.directory?(root+"\\"+entry) and !(entry =='.' || entry == '..') }

      games.each do |game|
        game_folder = root + "\\" + game

        learning_case_files =  Dir.entries(game_folder).select {|entry| !(entry =='.' || entry == '..') }

        learning_case_files.each do |learning_case_file|
          output_file = path + "\\learningcases\\processed\\" + game + "\\" + learning_case_file.split('.')[0] + ".csv"
          process_learning_case (game_folder + "\\" + learning_case_file), output_file
        end
      end
    end

    private

    def self.safe_csv_readline doc
      line = nil
      if !doc.eof?
        line = doc.readline.split ','
      end
      line
    end

  end
end