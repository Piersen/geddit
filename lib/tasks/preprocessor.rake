require 'core'

namespace :preprocessor do

  desc "Process usage events"
  task :process_usage_events, :gaze_data_path, :gui_change_log_path, :custom_event_log_path, :output_path do |t, args|
    Core::Preprocessor.process_usage_events args[:gaze_data_path], args[:gui_change_log_path], args[:custom_event_log_path], args[:output_path]
  end

end
