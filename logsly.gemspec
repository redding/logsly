# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logsly/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "logsly"
  gem.version     = Logsly::VERSION
  gem.description = %q{Create custom loggers.}
  gem.summary     = %q{Create custom loggers.}

  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.homepage    = "http://github.com/redding/logsly"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert", ["~> 1.0"])

  gem.add_dependency("ns-options",  ["~> 1.0"])
  gem.add_dependency("logging",     ["~> 1.8.0"])

end
