#!/usr/bin/env rake
require 'rake'
require "rubygems"
require "bundler/gem_tasks"

Bundler.setup(:default, :test)


task :spec do
  begin
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new("spec") do |spec|
      spec.pattern = "spec/**/*_spec.rb"
    end

    RSpec::Core::RakeTask.new('spec:progress') do |spec|
      spec.rspec_opts = %w(--format progress)
      spec.pattern = "spec/**/*_spec.rb"
    end
  rescue NameError, LoadError => e
    puts e
  end
end



task default: :spec