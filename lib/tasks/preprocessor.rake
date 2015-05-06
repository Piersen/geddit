require 'core'

namespace :preprocessor do

  desc "Process usage events"
  task :process_usage_events, :gaze_data_path, :gui_change_log_path, :custom_event_log_path, :output_path do |t, args|
    Core::Preprocessor.process_usage_events args[:gaze_data_path], args[:gui_change_log_path], args[:custom_event_log_path], args[:output_path]
  end

  desc "Mass process usage events found in a directory"
  task :mass_process_usage_events, :path do |t, args|
    Core::Preprocessor.mass_process_usage_events args[:path]
  end

  desc "Process learning case"
  task :process_learning_case, :input_path, :output_path do |t, args|
    Core::Preprocessor.process_learning_case args[:input_path], args[:output_path]
  end

  desc "Mass process learning cases found in a directory"
  task :mass_process_learning_cases, :path do |t, args|
    Core::Preprocessor.mass_process_learning_cases args[:path]
  end

end
