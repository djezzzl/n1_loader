# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # A patch to {N1Loader::LoaderCollection} to setup lazy context lazily.
    module LoaderCollectionPatch
      attr_accessor :context_setup

      def with(**args)
        result = super

        result.context_setup = context_setup if context_setup && result.context_setup.nil?

        result
      end
    end
  end
end
