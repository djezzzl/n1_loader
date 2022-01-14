# frozen_string_literal: true

RSpec.describe N1Loader do
  let(:loader) do
    Class.new(N1Loader::Loader) do
      def perform(elements)
        elements.each { |element| fulfill(element, [element]) }
      end
    end
  end

  let(:klass) do
    custom_loader = loader

    Class.new do
      include N1Loader::Loadable

      class << self
        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end

      n1_load :inline do |elements|
        elements.first.class.perform!

        elements.each { |element| fulfill(element, [element]) }
      end

      n1_load :custom, custom_loader

      n1_load :single_optimized do
        def single(element)
          [element]
        end

        def perform(_elements)
          raise "unknown"
        end
      end

      n1_load :missing_fulfill do
        def perform(elements)
          elements.group_by(&:itself)
        end
      end

      n1_load :with_arguments do
        def perform(elements, something, anything)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end
      end

      n1_load :with_custom_arguments_key do
        def perform(elements, something, anything)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end

        def self.arguments_key(something, anything)
          something + anything
        end
      end
    end
  end

  let(:object) { klass.new }
  let(:objects) { [klass.new, klass.new] }

  context "when fulfill was not used" do
    it "throws error" do
      expect { object.missing_fulfill }
        .to raise_error(N1Loader::NotFilled, "Nothing was preloaded, perhaps you forgot to use fulfill method")
    end
  end

  describe "arguments support" do
    it "has to receive all arguments" do
      expect { object.with_arguments }.to raise_error(ArgumentError)
      expect { object.with_arguments("something") }.to raise_error(ArgumentError)
      expect { object.with_arguments("something", anything: "anything") }.to raise_error(ArgumentError)

      expect(object.with_arguments("something", "anything")).to eq([object, "something", "anything"])
    end

    it "can have custom arguments key" do
      # The following two has the same result for custom key, so we only do one perform
      expect { object.with_custom_arguments_key(1, 2) }.to change(klass, :count).by(1)
      expect { object.with_custom_arguments_key(2, 1) }.not_to change(klass, :count)

      expect { object.with_custom_arguments_key(2, 3) }.to change(klass, :count).by(1)
    end

    it "works with preloading" do
      N1Loader::Preloader.new(objects).preload(:with_arguments)

      expect do
        objects.each do |object|
          expect(object.with_arguments("something", "anything")).to eq([object, "something", "anything"])
        end
      end.to change(klass, :count).by(1)
    end

    it "caches based on arguments" do
      N1Loader::Preloader.new(objects).preload(:with_arguments)

      expect do
        objects.each { |object| object.with_arguments("something", "anything") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments("something2", "anything") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments("something", "anything2") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments("something", "anything") }
      end.not_to change(klass, :count)
    end

    it "supports reloading" do
      expect do
        object.with_arguments("something", "anything")
      end.to change(klass, :count).by(1)

      expect do
        object.with_arguments("something", "anything", reload: true)
      end.to change(klass, :count).by(1)

      expect do
        object.with_arguments("something", "anything")
      end.not_to change(klass, :count)
    end
  end

  describe "optimization for single object" do
    it "uses optimization" do
      expect(object.single_optimized).to eq([object])

      N1Loader::Preloader.new(objects).preload(:single_optimized)
      expect { objects.map(&:single_optimized) }.to raise_error(StandardError, "unknown")
    end
  end

  describe "isolated loaders" do
    it "does not need injection" do
      instance = loader.new(objects)

      objects.each do |object|
        expect(instance.for(object)).to eq([object])
      end
    end

    it "checks that element was provided" do
      instance = loader.new(objects)

      objects.each do |object|
        expect(instance.for(object)).to eq([object])
      end
      expect do
        instance.for(object)
      end.to raise_error(N1Loader::NotLoaded, "The data was not preloaded for the given element")
    end
  end

  describe "reloading" do
    context "with preloading" do
      it "reloads cached data" do
        N1Loader::Preloader.new(objects).preload(:inline)

        expect { objects.map(&:inline) }.to change(klass, :count).by(1)

        N1Loader::Preloader.new(objects).preload(:inline)
        expect { objects.map(&:inline) }.to change(klass, :count).by(1)
        expect { objects.map(&:inline) }.not_to change(klass, :count)
      end
    end

    context "without preloading" do
      it "reloads cached data" do
        expect { object.inline }.to change(klass, :count).by(1)
        expect { object.inline(reload: true) }.to change(klass, :count).by(1)
        expect { object.inline(reload: false) }.not_to change(klass, :count)
        expect { object.inline }.not_to change(klass, :count)
      end
    end
  end

  context "with custom loader" do
    it "works" do
      expect(object.custom).to eq([object])
    end
  end

  context "without preloading" do
    it "returns right data" do
      expect(object.inline).to eq([object])
    end

    it "caches data" do
      expect { object.inline }.to change(klass, :count).by(1)
      expect { object.inline }.not_to change(klass, :count)
    end
  end

  context "with preloading" do
    it "returns right data" do
      N1Loader::Preloader.new(objects).preload(:inline)

      expect(objects.first.inline).to eq([objects.first])
      expect(objects.last.inline).to eq([objects.last])
    end

    it "lazy loads data" do
      expect { N1Loader::Preloader.new(objects).preload(:inline) }.not_to change(klass, :count)
      expect { objects.map(&:inline) }.to change(klass, :count).by(1)
    end

    it "uses preloaded data" do
      N1Loader::Preloader.new(objects).preload(:inline)

      expect { objects.map(&:inline) }.to change(klass, :count).by(1)
      expect { objects.map(&:inline) }.not_to change(klass, :count)
    end
  end
end
