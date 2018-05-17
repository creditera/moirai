# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moirai/version'

Gem::Specification.new do |spec|
  spec.name          = "moirai"
  spec.version       = Moirai::VERSION
  spec.authors       = ["Mitch Monsen", "Logan McPhail", "John Thornton"]
  spec.email         = ["mitch@nav.com", "loganm@nav.com", "johnnyt@nav.com"]

  spec.summary       = "A gem for managing a multi-threaded worker process."
  spec.description   = "A gem for managing a multi-threaded worker process."
  spec.homepage      = "https://github.com/creditera/moirai"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "simplecov", "~> 0.16.1"
  spec.add_dependency "rack"
  spec.add_dependency "nsq-ruby"
  spec.add_dependency "request_store"
end
