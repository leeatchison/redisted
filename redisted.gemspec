# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redisted/version"

Gem::Specification.new do |s|
  s.name        = "redisted"
  s.version     = Redisted::VERSION
  s.authors     = ["Lee Atchison"]
  s.email       = ["lee@leeatchison.com"]
  s.homepage    = ""
  s.summary     = %q{Rails models based on Redis.}
  s.description = %q{Rails models based Redis.}

  s.rubyforge_project = "redisted"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rails"
  s.add_development_dependency "rspec"
  s.add_development_dependency "capybara"
  s.add_development_dependency "capybara"
  s.add_runtime_dependency "redis"
end
