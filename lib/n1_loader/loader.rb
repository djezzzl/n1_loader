# frozen_string_literal: true

module N1Loader
  # Loader that performs the loading.
  #
  # Subclasses must define +perform+ method that accepts single argument
  # and returns hash where key is the element and value is what we want to load.
  class Loader
    def initialize(elements)
      @elements = elements
    end

    def perform(_elements)
      raise NotImplemented, "Subclasses have to implement the method"
    end

    def loaded
      @loaded ||= perform(elements)
    end

    def for(element)
      raise NotLoaded, "The data was not preloaded for the given element" unless elements.include?(element)

      loaded.compare_by_identity[element]
    end

    private

    attr_reader :elements
  end
end
