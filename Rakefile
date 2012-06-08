require 'bundler/gem_tasks'
require 'rake/testtask'

Dir.glob('tasks/*.rake').each { |r| import r }

Rake::TestTask.new
task :default => :test
