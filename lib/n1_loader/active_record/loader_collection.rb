# frozen_string_literal: true

N1Loader::LoaderCollection.define_method :preloaded_records do
  unless loader_class.instance_method(:perform).arity == 1
    raise N1Loader::ActiveRecord::InvalidPreloading, "Cannot preload loader with arguments"
  end

  with.preloaded_records
end
