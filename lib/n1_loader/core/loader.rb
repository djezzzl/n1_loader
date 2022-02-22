# frozen_string_literal: true

module N1Loader
  # Loader that performs the loading.
  #
  # Subclasses must define +perform+ method that accepts single argument
  # and returns hash where key is the element and value is what we want to load.
  class Loader
    class << self
      attr_reader :arguments

      # Defines an argument that can be accessed within the loader.
      #
      # First defined argument will have the value of first passed argument,
      # meaning the order is important.
      def argument(name)
        @arguments ||= []
        index = @arguments.size
        define_method(name) { args[index] }
        @arguments << name
      end

      def arguments_key(*args)
        args.map(&:object_id)
      end
    end

    def initialize(elements, *args)
      @elements = elements
      @args = args
    end

    def for(element)
      if loaded.empty? && elements.any?
        raise NotFilled, "Nothing was preloaded, perhaps you forgot to use fulfill method"
      end
      raise NotLoaded, "The data was not preloaded for the given element" unless loaded.key?(element)

      loaded[element]
    end

    private

    attr_reader :elements, :args

    def check_arguments!
      return unless (required = self.class.arguments)
      return if required.size == args.size

      raise MissingArgument, "Loader defined #{required.size} arguments but #{args.size} were given"
    end

    def perform(_elements)
      raise NotImplemented, "Subclasses have to implement the method"
    end

    def fulfill(element, value)
      @loaded[element] = value
    end

    def loaded # rubocop:disable Metrics/AbcSize
      return @loaded if @loaded

      check_arguments!

      @loaded = {}.compare_by_identity

      if elements.size == 1 && respond_to?(:single)
        fulfill(elements.first, single(elements.first, *args))
      elsif elements.any?
        perform(elements, *args)
      end

      @loaded
    end
  end
end
