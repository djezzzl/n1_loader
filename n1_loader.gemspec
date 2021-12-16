# frozen_string_literal: true

require_relative "lib/n1_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "n1_loader"
  spec.version       = N1Loader::VERSION
  spec.authors       = ["Evgeniy Demin"]
  spec.email         = ["lawliet.djez@gmail.com"]

  spec.summary       = "N+1 loader to solve the problem for good."
  spec.homepage      = "https://github.com/djezzzl/n1_loader"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/djezzzl/database_consistency"
  spec.metadata["changelog_uri"] = "https://github.com/djezzzl/database_consistency/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
