# frozen_string_literal: true
# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "http-parser/version"

Gem::Specification.new do |s|
  s.name        = "http-parser"
  s.version     = HttpParser::VERSION
  s.authors     = ["Stephen von Takach"]
  s.email       = ["steve@cotag.me"]
  s.license     = 'MIT'
  s.homepage    = "https://github.com/cotag/http-parser"
  s.summary     = "Ruby bindings to joyent/http-parser"
  s.description = <<-EOF
    A super fast http parser for ruby.
    Cross platform and multiple ruby implementation support thanks to ffi.
  EOF


  s.add_dependency 'ffi', '~> 1.12'

  s.add_development_dependency 'rake',  '~> 11.2'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'yard',  '~> 0.9'


  s.files = Dir["{lib}/**/*"]

  s.require_paths = ["lib"]
end
