# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

require "gem_docs"
GemDocs.install

########################################################################
# Rubocop tasks
########################################################################
require "rubocop/rake_task"

desc "Run rubocop under `bundle exec`"
task :rubocop do
  opts = (ENV['RUBOCOP_OPTS'] || '').split
  Bundler.with_unbundled_env do
    sh 'bundle', 'exec', 'rubocop', *opts
  end
end

task :default => [:spec, :rubocop]
