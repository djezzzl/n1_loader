module N1Loader
  module ArLazyPreload
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