# frozen_string_literal: true

# Raised when a single object without ArLazyPreload context was passed to an isolated loader.
N1Loader::Loader::MissingArLazyPreloadContext = Class.new(StandardError)

# Defines a singleton method method that allows isolated loaders
# to use ArLazyPreload context without passing sibling records.
N1Loader::Loader.define_singleton_method(:for) do |element, **args|
  # It is required to have an ArLazyPreload context defined
  if !element.respond_to?(:lazy_preload_context) || element.lazy_preload_context.nil?
    raise N1Loader::Loader::MissingArLazyPreloadContext
  end

  # Fetch or initialize loader from ArLazyPreload context
  loader_collection = element.lazy_preload_context.fetch_n1_loader_collection(self) do
    context_setup = lambda { |records|
      N1Loader::ArLazyPreload::AssociatedContextBuilder.prepare(
        parent_context: element.lazy_preload_context,
        association_name: "cached_n1_loader_collection_#{self}".downcase.to_sym,
        records: records
      )
    }

    N1Loader::LoaderCollection.new(self, element.lazy_preload_context.records).tap do |collection|
      collection.context_setup = context_setup
    end
  end

  # Fetch value from loader
  loader_collection.with(**args).for(element)
end
