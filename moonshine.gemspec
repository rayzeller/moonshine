# -*- encoding: utf-8 -*-
require File.expand_path('../lib/moonshine/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ray Zeller"]
  gem.email         = ["rayzeller@gmail.com"]
  gem.description   = %q{A Cube client for Ruby (http://square.github.com/cube).}
  gem.summary       = %q{A Cube client for Ruby (http://square.github.com/cube).}
  gem.homepage      = "https://github.com/rayzeller/moonshine"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "moonshine"
  gem.require_paths = ["lib"]
  gem.version       = Moonshine::VERSION

  gem.add_dependency "mongoid", "> 3.1.0"
end