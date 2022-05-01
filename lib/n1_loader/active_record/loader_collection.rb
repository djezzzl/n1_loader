# frozen_string_literal: true

N1Loader::LoaderCollection.define_method :preloaded_records do
  raise N1Loader::ActiveRecord::InvalidPreloading, "Cannot preload loader with arguments" if loader_class.arguments

  with.preloaded_records
end

N1Loader::LoaderCollection.define_method :runnable_loaders do
  [self]
end

N1Loader::LoaderCollection.define_method :run? do
  true
end