# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    module Loadable # :nodoc:
      def n1_loader(name)
        return n1_loaders[name] if n1_loaders[name]

        ContextAdapter.new(lazy_preload_context).try_preload_lazily(name) if respond_to?(:lazy_preload_context)

        super
      end
    end
  end
end
