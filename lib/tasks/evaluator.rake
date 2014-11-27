require 'core'

namespace :evaluator do

  desc "Evaluate a learning case"
  task :parse_learning_case, :input_path, :output_path do |t, args|
    lc = Core::Evaluator::LearningCase.new args[:input_path]
    lc.save args[:output_path]
  end

end
