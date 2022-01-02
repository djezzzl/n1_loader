# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in n1_loader.gemspec
gemspec

# Hack to make Github work with Circle CI job names with slashes
gemfiles = []
gemfiles << "activerecord-gemfiles/#{ENV["ACTIVERECORD_GEMFILE"]}.gemfile" if ENV["ACTIVERECORD_GEMFILE"]
gemfiles << "ar_lazy_preload-gemfiles/#{ENV["AR_LAZY_PRELOAD_GEMFILE"]}.gemfile" if ENV["AR_LAZY_PRELOAD_GEMFILE"]

gemfiles.each do |path|
  eval(File.read(path)) # rubocop:disable Security/Eval
end
