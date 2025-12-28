# frozen_string_literal: true

require_relative "lib/n1_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "n1_loader"
  spec.version       = N1Loader::VERSION
  spec.authors       = ["Evgeniy Demin"]
  spec.email         = ["lawliet.djez@gmail.com"]

  spec.summary       = "Loader to solve N+1 issue for good."
  spec.homepage      = "https://github.com/djezzzl/n1_loader"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/djezzzl/n1_loader"
  spec.metadata["changelog_uri"] = "https://github.com/djezzzl/n1_loader/master/CHANGELOG.md"
  spec.metadata["funding_uri"] = "https://opencollective.com/n1_loader#support"

  spec.files = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "mutex_m"

  spec.add_development_dependency "activerecord", ">= 5"
  spec.add_development_dependency "ar_lazy_preload", ">= 0.6"
  spec.add_development_dependency "db-query-matchers", "~> 0.11"
  spec.add_development_dependency "graphql", "~> 2.0"
  spec.add_development_dependency "rails", ">= 5"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4"
  spec.add_development_dependency "rubocop", "~> 1.7"
  spec.add_development_dependency "sqlite3", "~> 1.3"
end
