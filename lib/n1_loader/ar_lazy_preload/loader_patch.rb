# frozen_string_literal: true

module N1Loader
  module ArLazyPreload
    # A patch to {N1Loader::Loader} to setup lazy context lazily.
    module LoaderPatch
      attr_accessor :context_setup

      def loaded
        return @loaded if @loaded

        super

        context_setup&.call(preloaded_records)

        @loaded
      end
    end
  end
end
