# frozen_string_literal: true

require "n1_loader"
require "db-query-matchers"

DBQueryMatchers.configure do |config|
  config.schemaless = true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def ar_lazy_preload_defined?
    defined?(ArLazyPreload)
  end

  def ar_version
    ActiveRecord::VERSION::MAJOR
  end
end
