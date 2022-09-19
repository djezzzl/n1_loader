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
      #
      # @param name [Symbol]
      # @param opts [Hash]
      # @option opts [Boolean] optional false by default
      # @option opts [Proc] default
      def argument(name, **opts)
        opts[:optional] = true if opts[:default]

        @arguments ||= []

        define_method(name) do
          args.fetch(name) { opts[:default]&.call }
        end

        @arguments << opts.merge(name: name)
      end

      # Defines a custom cache key that is calculated for passed arguments.
      def cache_key(&block)
        define_method(:cache_key) do
          check_arguments!
          instance_exec(&block)
        end
      end
    end

    def initialize(elements, **args)
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

    def cache_key
      check_arguments!
      args.values.map(&:object_id)
    end

    private

    attr_reader :elements, :args

    def check_missing_arguments! # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return unless (arguments = self.class.arguments)

      min = arguments.count { |argument| !argument[:optional] }
      max = arguments.count

      return if args.size >= min && args.size <= max

      str =
        if min == max
          max.to_s
        else
          "#{min}..#{max}"
        end

      raise MissingArgument, "Loader requires #{str} arguments but #{args.size} were given"
    end

    def check_arguments!
      check_missing_arguments!
      check_invalid_arguments!
    end

    def check_invalid_arguments!
      return unless (arguments = self.class.arguments)

      args.each_key do |arg|
        next if arguments.find { |argument| argument[:name] == arg }

        raise InvalidArgument, "Loader doesn't define #{arg} argument"
      end
    end

    def perform(_elements)
      raise NotImplemented, "Subclasses have to implement the method"
    end

    def fulfill(element, value)
      @loaded[element] = value
    end

    def loaded
      return @loaded if @loaded

      check_arguments!

      @loaded = {}.compare_by_identity

      if elements.size == 1 && respond_to?(:single)
        fulfill(elements.first, single(elements.first))
      elsif elements.any?
        perform(elements)
      end

      @loaded
    end
  end
end
