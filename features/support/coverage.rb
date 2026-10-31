require "simplecov"

SimpleCov.command_name "Cucumber"
SimpleCov.start "rails" do
  coverage_dir "coverage/cucumber"
  enable_coverage :branch
  skip "/spec/"
  skip "/test/"
  skip "/features/"
end
