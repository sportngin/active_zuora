# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_zuora/version"
authors = {
  "Ed Lebert" => "edlebert@gmail.com",
  "Andy Fleener" => "andy.fleener@sportngin.com",
}
Gem::Specification.new do |s|
  s.name             = "active_zuora"
  s.version          = ActiveZuora::VERSION.to_s
  s.platform         = Gem::Platform::RUBY
  s.authors          = authors.keys
  s.email            = authors.values
  s.homepage         = "https://github.com/sportngin/active_zuora"
  s.summary          = %q{ActiveZuora - Zuora API that looks and feels like ActiveRecord.}
  s.description      = %q{ActiveZuora - Zuora API based on ActiveModel and auto-generated from your zuora.wsdl.}
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths    = ["lib"]
  s.license          = "MIT"
  s.extra_rdoc_files = [ "README.md" ]

  s.add_runtime_dependency('akami', ["~> 1.2.0"])
  s.add_runtime_dependency('activesupport', [">= 3.0.0"])
  s.add_runtime_dependency('activemodel', [">= 3.0.0"])
  s.add_runtime_dependency('builder', [">= 2.1.2"])
  s.add_runtime_dependency('gyoku', ["~> 0.4.5"])
  s.add_runtime_dependency('httpi', ["~> 1.1.0"])
  s.add_runtime_dependency('nokogiri', [">= 1.4.0"])
  s.add_runtime_dependency('nori', ["~> 1.1.0"])
  s.add_runtime_dependency('rack', ["< 3"])
  s.add_runtime_dependency('wasabi', ["~> 2.5.0"])

  s.add_development_dependency('rake', [">= 0.8.7"])
  s.add_development_dependency('rspec', [">= 3.0.0"])
end
