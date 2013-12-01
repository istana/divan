# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'divan/version'

Gem::Specification.new do |spec|
  spec.name          = "divan"
  spec.version       = Divan::VERSION
  spec.authors       = ["Ivan Stana"]
  spec.email         = ["stiipa@centrum.sk"]
  spec.description   = %q{Library to communicate with CouchDB in easy way.}
  spec.summary       = %q{Communitacate using this library with CouchDB easily. Uses ActiveModel for models, to use forms easily. You may also query for hashes only.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  
  spec.add_dependency "oj", "~> 2.2"
  spec.add_dependency "multi_json", "~> 1.8"
  spec.add_dependency "typhoeus"
  spec.add_dependency "activesupport", "~> 4.0"
  spec.add_dependency "dotted_hash"
end
