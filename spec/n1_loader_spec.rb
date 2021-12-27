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

      n1_load :data do |elements|
        elements.first.class.perform!

        elements.each { |element| fulfill(element, [element]) }
      end

      n1_load :something, custom_loader

      n1_load :anything do
        def single(element)
          [element]
        end

        def perform(_elements)
          raise "unknown"
        end
      end
    end
  end

  context "when fulfill was not used" do
    it "throws an error" do
      elements = [1, 2]

      loader = Class.new(N1Loader::Loader) do
        def perform(elements)
          elements.group_by(&:itself)
        end
      end

      expect do
        loader.new(elements).for(elements.first)
      end.to raise_error(N1Loader::NotFilled,
                         "Nothing was preloaded, perhaps you forgot to use fulfill method")
    end
  end

  describe "optimization for single object" do
    it "uses optimization" do
      element = klass.new
      expect(element.anything).to eq([element])

      elements = [klass.new, klass.new]
      N1Loader::Preloader.new(elements).preload(:anything)

      expect { elements.map(&:anything) }.to raise_error(StandardError, "unknown")
    end
  end

  describe "isolated loaders" do
    it "does not need injection" do
      elements = [1, 2]

      instance = loader.new(elements)

      elements.each do |element|
        expect(instance.for(element)).to eq([element])
      end
    end

    it "checks that element was provided" do
      elements = [1, 2]

      instance = loader.new(elements)

      elements.each do |element|
        expect(instance.for(element)).to eq([element])
      end
      expect { instance.for(3) }.to raise_error(N1Loader::NotLoaded, "The data was not preloaded for the given element")
    end
  end

  describe "reloading" do
    context "with preloading" do
      let(:objects) { [klass.new, klass.new] }

      it "reloads cached data" do
        N1Loader::Preloader.new(objects).preload(:data)

        expect { objects.map(&:data) }.to change(klass, :count).from(0).to(1)

        N1Loader::Preloader.new(objects).preload(:data)
        expect { objects.map(&:data) }.to change(klass, :count).from(1).to(2)
        expect { objects.map(&:data) }.not_to change(klass, :count)
      end
    end

    context "without preloading" do
      let(:object) { klass.new }

      it "reloads cached data" do
        expect { object.data }.to change(klass, :count).from(0).to(1)
        expect { object.data(reload: true) }.to change(klass, :count).from(1).to(2)
        expect { object.data(reload: false) }.not_to change(klass, :count)
        expect { object.data }.not_to change(klass, :count)
      end
    end
  end

  context "with custom loader" do
    let(:object) { klass.new }

    it "works" do
      expect(object.something).to eq([object])
    end
  end

  context "without preloading" do
    let(:object) { klass.new }

    it "returns right data" do
      expect(object.data).to eq([object])
    end

    it "caches data" do
      expect { object.data }.to change(klass, :count).from(0).to(1)
      expect { object.data }.not_to change(klass, :count)
    end
  end

  context "with preloading" do
    let(:objects) { [klass.new, klass.new] }

    it "returns right data" do
      N1Loader::Preloader.new(objects).preload(:data)

      expect(objects.first.data).to eq([objects.first])
      expect(objects.last.data).to eq([objects.last])
    end

    it "lazy loads data" do
      expect { N1Loader::Preloader.new(objects).preload(:data) }.not_to change(klass, :count)
      expect { objects.map(&:data) }.to change(klass, :count).from(0).to(1)
    end

    it "uses preloaded data" do
      N1Loader::Preloader.new(objects).preload(:data)

      expect { objects.map(&:data) }.to change(klass, :count).from(0).to(1)
      expect { objects.map(&:data) }.not_to change(klass, :count)
    end
  end
end
