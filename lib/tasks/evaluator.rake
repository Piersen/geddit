require 'core'

namespace :evaluator do

  desc "Evaluate a learning case"
  task :evaluate_learning_case, :interaction_events_path, :learning_case_path do |t, args|
    Core::Evaluator.evaluate_learning_case args[:learning_case_path], args[:interaction_events_path]
  end

  desc "Mass evaluate learning cases"
  task :mass_evaluate_learning_cases, :path do |t, args|
    Core::Evaluator.mass_evaluate_learning_cases args[:path]
  end

end
