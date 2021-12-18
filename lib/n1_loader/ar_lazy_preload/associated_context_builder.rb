# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # Context builder for N1Loader
    class AssociatedContextBuilder < ::ArLazyPreload::AssociatedContextBuilder
      def perform
        ::ArLazyPreload::Context.register(
          records: parent_context.records.flat_map(&association_name),
          association_tree: child_association_tree,
          auto_preload: parent_context.auto_preload?
        )
      end
    end
  end
end
