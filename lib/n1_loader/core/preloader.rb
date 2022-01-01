# frozen_string_literal: true

module N1Loader
  # Preloader that lazily preloads data to every element.
  #
  # It supports multiple keys.
  #
  # It supports elements that have different loaders under the same key.
  # It will properly preload data to each of the element of the similar group.
  class Preloader
    attr_reader :elements

    def initialize(elements)
      @elements = elements
    end

    def preload(*keys)
      keys.flatten(1).flat_map do |key|
        elements
          .group_by { |element| element.class.n1_loader(key) }
          .map do |loader_class, grouped_elements|
            loader_collection = N1Loader::LoaderCollection.new(loader_class, grouped_elements)
            grouped_elements.each { |grouped_element| grouped_element.n1_loader_set(key, loader_collection) }
            loader_collection
          end
      end
    end
  end
end
