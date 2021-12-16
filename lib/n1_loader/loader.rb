# frozen_string_literal: true

module N1Loader
  class Loader
    def initialize(elements)
      @elements = elements
    end

    def perform(_elements)
      raise "Not implemented"
    end

    def loaded
      @loaded ||= perform(elements)
    end

    def for(element)
      raise "Not loaded" unless elements.include?(element)

      loaded.compare_by_identity[element]
    end

    private

    attr_reader :elements
  end
end
