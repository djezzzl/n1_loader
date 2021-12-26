# frozen_string_literal: true

RSpec.describe N1Loader do
  let(:klass) do
    custom_loader = Class.new(N1Loader::Loader) do
      def perform(elements)
        elements.group_by(&:itself)
      end
    end

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

        elements.group_by(&:itself)
      end

      n1_load :something, custom_loader
    end
  end

  describe 'reloading' do
    context 'with preloading' do
      let(:objects) { [klass.new, klass.new] }

      it 'reloads cached data' do
        N1Loader::Preloader.new(objects).preload(:data)

        expect { objects.map(&:data) }.to change(klass, :count).from(0).to(1)

        N1Loader::Preloader.new(objects).preload(:data)
        expect { objects.map(&:data) }.to change(klass, :count).from(1).to(2)
        expect { objects.map(&:data) }.not_to change(klass, :count)
      end
    end

    context 'without preloading' do
      let(:object) { klass.new }

      it 'reloads cached data' do
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
