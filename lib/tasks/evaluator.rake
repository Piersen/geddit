require 'core'

namespace :evaluator do

  desc "Evaluate a learning case"
  task :evaluate_learning_case, :interaction_events_path, :learning_case_path do |t, args|
    learning_case = Core::Evaluator::LearningCase.new args[:learning_case_path]
    events = Core::Evaluator::InteractionEvent.load_all args[:interaction_events_path]
    learning_case.evaluate events
  end

end
