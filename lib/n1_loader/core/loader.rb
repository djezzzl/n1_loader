# frozen_string_literal: true

module N1Loader
  # Loader that performs the loading.
  #
  # Subclasses must define +perform+ method that accepts single argument
  # and returns hash where key is the element and value is what we want to load.
  class Loader
    prepend MonitorMixin

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
          args.fetch(name) { args[name] = opts[:default]&.call }
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
      return unless loaded?

      if loaded_by_identity.empty? && elements.any?
        raise NotFilled, "Nothing was preloaded, perhaps you forgot to use fulfill method"
      end

      return loaded_by_identity[element] if loaded_by_identity.key?(element)
      return loaded_by_value[element] if loaded_by_value.key?(element)

      raise NotLoaded, "The data was not preloaded for the given element"
    end

    def cache_key
      check_arguments!
      args.values.map(&:object_id)
    end

    private

    attr_reader :elements, :args, :loaded_by_value, :loaded_by_identity

    def check_missing_arguments!
      return unless (arguments = self.class.arguments)

      required_arguments = required_arguments(arguments)

      return if required_arguments.all? { |argument| args.key?(argument) }

      missing_arguments = required_arguments.reject { |argument| args.key?(argument) }

      list = missing_arguments.map { |argument| ":#{argument}" }.join(", ")

      raise MissingArgument, "Loader requires [#{list}] arguments but they are missing"
    end

    def required_arguments(args)
      args.reject { |argument| argument[:optional] }
          .map { |argument| argument[:name] }
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
      loaded_by_identity[element] = value
      loaded_by_value[element] = value
    end

    def loaded?
      return true if @already_loaded

      synchronize { non_thread_safe_loading unless @already_loaded }

      true
    end

    def non_thread_safe_loading # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return if @already_loaded

      check_arguments!

      @loaded_by_identity = {}.compare_by_identity
      @loaded_by_value = {}

      if respond_to?(:single) && elements.size == 1
        fulfill(elements.first, single(elements.first))
      elsif elements.any?
        elements.each { |el| el.n1_bind_to(elements) if el.respond_to?(:n1_bind_to) }
        perform(elements)
      end

      @already_loaded = true
    end
  end
end
