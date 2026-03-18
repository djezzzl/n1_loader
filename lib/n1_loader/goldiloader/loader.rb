# frozen_string_literal: true

# Raised when a single object without Goldiloader context support was passed to an isolated loader.
N1Loader::Loader::UnsupportedGoldiloader = Class.new(StandardError)

# Defines a singleton method that allows isolated loaders
# to use Goldiloader context without passing sibling records.
N1Loader::Loader.define_singleton_method(:for) do |element, **args|
  # It is required to have a Goldiloader context supported
  raise N1Loader::Loader::UnsupportedGoldiloader unless element.respond_to?(:auto_include_context)

  context = element.auto_include_context

  # Fetch or initialize loader from Goldiloader context
  loader_collection = context.fetch_n1_loader_collection(self) do
    context_setup = lambda { |records|
      ar_records = records.flatten(1).select { |record| record.respond_to?(:auto_include_context=) }
      ::Goldiloader::AutoIncludeContext.register_models(ar_records) unless ar_records.empty?
    }

    N1Loader::LoaderCollection.new(self, context.models).tap do |collection|
      collection.context_setup = context_setup
    end
  end

  # Fetch value from loader
  loader_collection.with(**args).for(element)
end
