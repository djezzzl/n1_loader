module N1Loader
  module ArLazyPreload
    class Preloader < N1Loader::Preloader
      def initialize(elements, context_setup)
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