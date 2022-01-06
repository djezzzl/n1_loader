# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # A patch to {N1Loader::Preloader} setup lazy context lazily.
    module PreloaderPatch
      def initialize(elements, context_setup = nil)
        super(elements)
        @context_setup = context_setup
      end

      def preload(*keys)
        super.each do |loader_collection|
          loader_collection.context_setup = context_setup
        end
      end

      private

      attr_reader :context_setup
    end
  end
end
