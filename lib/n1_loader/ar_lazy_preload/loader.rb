# frozen_string_literal: true

# Raised when a single object without ArLazyPreload context support was passed to an isolated loader.
N1Loader::Loader::UnsupportedArLazyPreload = Class.new(StandardError)

# Defines a singleton method method that allows isolated loaders
# to use ArLazyPreload context without passing sibling records.
N1Loader::Loader.define_singleton_method(:for) do |element, **args|
  # It is required to have an ArLazyPreload context supported
  raise N1Loader::Loader::UnsupportedArLazyPreload unless element.respond_to?(:lazy_preload_context)

  if element.lazy_preload_context.nil?
    ArLazyPreload::Context.register(
      records: [element],
      association_tree: [],
      auto_preload: true
    )
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
