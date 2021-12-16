# frozen_string_literal: true

RSpec.describe N1Loader do
  let(:klass) do
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
  end
end
