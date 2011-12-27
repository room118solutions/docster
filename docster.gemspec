# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "docster/version"

Gem::Specification.new do |s|
  s.name        = "docster"
  s.version     = Docster::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jim Ryan", "Chris Gunther"]
  s.email       = ["info@room118solutions.com"]
  s.homepage    = ""
  s.summary     = %q{Generates searchable documentation for your ruby project}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "docster"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
