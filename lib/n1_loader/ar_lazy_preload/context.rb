# frozen_string_literal: true

# Returns cached N1Loader::LoaderCollection from context for a loader.
# In case there is none yet, saves passed block to a cache.
ArLazyPreload::Contexts::BaseContext.define_method :fetch_n1_loader_collection do |loader, &block|
  (@n1_loader_collections ||= {})[loader] ||= block.call
end
