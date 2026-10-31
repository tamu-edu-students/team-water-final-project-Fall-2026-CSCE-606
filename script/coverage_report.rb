require "simplecov"

reports = %w[ coverage/rspec/.resultset.json coverage/cucumber/.resultset.json ]
abort "Run both RSpec and Cucumber before combining coverage." unless reports.all? { |path| File.file?(path) }

SimpleCov.collate reports, "rails" do
  coverage_dir "coverage/combined"
  enable_coverage :branch
  skip "/spec/"
  skip "/test/"
  skip "/features/"
end
