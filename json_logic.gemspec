# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_logic/version'

Gem::Specification.new do |spec|
  spec.name          = 'json_logic'
  spec.version       = JSONLogic::VERSION
  spec.authors       = ['Kenneth Geerts', "Jordan Prince"]
  spec.email         = ['Kenneth.Geerts@gmail.com', "jordanmprince@gmail.com"]
  spec.homepage      = 'http://jsonlogic.com'
  spec.summary       = 'Build complex rules, serialize them as JSON, and execute them in ruby'
  spec.description   = 'Build complex rules, serialize them as JSON, and execute them in ruby. See http://jsonlogic.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'bundler',  '~> 1.13'
  spec.add_development_dependency 'rake',     '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
