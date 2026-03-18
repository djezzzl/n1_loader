# frozen_string_literal: true

module N1Loader
  module Goldiloader
    module Loadable # :nodoc:
      def n1_loader(name)
        return n1_loaders[name] if n1_loaders[name]

        ContextAdapter.new(auto_include_context).try_preload_lazily(name) if respond_to?(:auto_include_context)

        super
      end
    end
  end
end
