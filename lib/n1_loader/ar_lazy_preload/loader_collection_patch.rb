module N1Loader
  module ArLazyPreload
    module LoaderCollectionPatch
      attr_accessor :context_setup

      def with(*args)
        result = super

        if context_setup && result.context_setup.nil?
          result.context_setup = context_setup
        end

        result
      end
    end
  end
end