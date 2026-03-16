# frozen_string_literal: true

N1Loader::Loader::UnsupportedGoldiloader = Class.new(StandardError)

N1Loader::Loader.define_singleton_method(:for) do |element, **args|
  raise N1Loader::Loader::UnsupportedGoldiloader unless element.respond_to?(:auto_include_context)

  loader_collection = element.auto_include_context.fetch_n1_loader_collection(self) do
    context_setup = lambda { |records|
      ar_records = records.flatten(1).select { |r| r.respond_to?(:auto_include_context=) }
      ::Goldiloader::AutoIncludeContext.register_models(ar_records) if ar_records.any?
    }

    N1Loader::LoaderCollection.new(self, element.auto_include_context.models).tap do |collection|
      collection.context_setup = context_setup
    end
  end

  loader_collection.with(**args).for(element)
end
