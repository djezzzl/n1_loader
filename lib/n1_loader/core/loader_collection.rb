# frozen_string_literal: true

module N1Loader
  # The class is used for storing collections of loaders for elements per set of arguments.
  class LoaderCollection
    attr_reader :loader_class, :elements

    def initialize(loader_class, elements)
      @loader_class = loader_class
      @elements = elements
    end

    def with(*args)
      loader = loader_class.new(elements, *args)

      loaders[loader.cache_key] ||= loader
    end

    private

    def loaders
      @loaders ||= {}
    end
  end
end
