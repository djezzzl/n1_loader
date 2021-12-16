# frozen_string_literal: true

module N1Loader
  class Preloader
    def preload(elements, keys)
      keys.each do |key|
        loader = elements.first.class.n1_loader(key).new(elements)

        elements.each do |element|
          element.n1_loader_set(key, loader)
        end
      end
    end
  end
end
