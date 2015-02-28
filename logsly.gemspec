# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logsly/version'

Gem::Specification.new do |gem|
  gem.name        = "logsly"
  gem.version     = Logsly::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.description = %q{Create custom loggers.}
  gem.summary     = %q{Create custom loggers.}
  gem.homepage    = "http://github.com/redding/logsly"
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert", ["~> 2.13"])

  gem.add_dependency("ns-options",  ["~> 1.1"])
  gem.add_dependency("logging",     ["~> 1.7"])

end
