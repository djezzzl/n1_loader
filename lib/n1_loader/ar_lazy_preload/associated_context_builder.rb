# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # Context builder for N1Loader
    class AssociatedContextBuilder < ::ArLazyPreload::AssociatedContextBuilder
      attr_reader :records

      def initialize(parent_context:, association_name:, records:)
        super(parent_context: parent_context, association_name: association_name)
        @records = records
      end

      def perform
        ::ArLazyPreload::Context.register(
          records: records.flatten(1).select { |record| record.respond_to?(:lazy_preload_context=) },
          association_tree: child_association_tree,
          auto_preload: parent_context.auto_preload?
        )
      end
    end
  end
end
