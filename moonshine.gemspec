# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/moonshine/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Ray Zeller"]
  gem.email         = ["rayzeller@gmail.com"]
  gem.description   = %q{An Analytics Module).}
  gem.summary       = %q{An Analytics Module).}
  gem.homepage      = "https://github.com/rayzeller/moonshine"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "moonshine"
  gem.require_paths = ["lib"]
  gem.version       = Moonshine::VERSION

  gem.add_dependency "mongoid", "~> 3.1.3"
  gem.add_dependency "deep_merge"
  gem.add_dependency "delayed_job"
  gem.add_development_dependency "rspec", "~>2.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency 'activerecord', '>= 3.1.0'
  gem.add_development_dependency 'delayed_job_mongoid'
end
