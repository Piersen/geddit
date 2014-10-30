require 'core'

namespace :evaluator do

  desc "Evaluate a learning case"
  task :parse_learning_case, :path do |t, args|
      Core::Evaluator::LearningCase.new args[:path]
  end

end
