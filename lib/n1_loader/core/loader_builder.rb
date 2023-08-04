# frozen_string_literal: true

module N1Loader
  # The class builds {N1Loader::Loader}
  class LoaderBuilder
    def self.build(&block)
      Class.new(N1Loader::Loader) do
        if block.arity == 1
          define_method(:perform, &block)
        else
          class_eval(&block)
        end
      end
    end
  end
end
