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

      n1_optimized :inline do |elements|
        elements.first.class.perform!

        elements.each { |element| fulfill(element, [element]) }
      end

      n1_optimized :sleepy do |elements|
        sleep(0.5)

        elements.first.class.perform!
        elements.each { |element| fulfill(element, [element]) }
      end

      n1_optimized :custom, custom_loader

      n1_optimized :single_optimized do
        def single(element)
          [element]
        end

        def perform(_elements)
          raise "unknown"
        end
      end

      n1_optimized :missing_fulfill do
        def perform(elements)
          elements.group_by(&:itself)
        end
      end

      n1_optimized :with_arguments do
        argument :something
        argument :anything

        def perform(elements)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end
      end

      n1_optimized :with_optional_argument do
        argument :something, optional: true
        argument :anything

        def perform(elements)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end
      end

      n1_optimized :with_default_argument do
        argument :something, default: -> { [] }
        argument :anything

        def perform(elements)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end
      end

      n1_optimized :with_custom_arguments_key do
        argument :something
        argument :anything

        cache_key { something + anything }

        def perform(elements)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something, anything])
          end
        end
      end

      n1_optimized :with_question_mark? do
        argument :something

        def perform(elements)
          elements.first.class.perform!

          elements.each do |element|
            fulfill(element, [element, something])
          end
        end
      end
    end
  end

  let(:child_klass) do
    Class.new(klass) do
      n1_optimized :child_something do |elements|
        elements.first.class.perform!

        elements.each do |element|
          fulfill(element, [element])
        end
      end
    end
  end

  let(:object) { klass.new }
  let(:objects) { [klass.new, klass.new] }

  it "works with unsupported objects" do
    expect do
      N1Loader::Preloader.new([object, 123]).preload(:with_arguments)
    end.not_to raise_error(NoMethodError)
  end

  describe "thread-safety" do
    it "is thread-safe" do
      N1Loader::Preloader.new(objects).preload(:sleepy)

      threads = []

      10.times do
        threads << Thread.new do
          objects.each do |obj|
            expect(obj.sleepy).to eq([obj])
          end
        end
      end
      threads.each(&:join)

      expect(klass.count).to eq(1)
    end
  end

  describe "error handling" do
    it "raises the same error on the subsequent calls" do
      faulty_klass = Class.new do
        include N1Loader::Loadable

        n1_optimized :faulty do |_|
          raise StandardError, "Something went wrong"
        end
      end

      faulty_object = faulty_klass.new

      expect { faulty_object.faulty }.to raise_error(StandardError, "Something went wrong")
      expect { faulty_object.faulty }.to raise_error(StandardError, "Something went wrong")
    end
  end

  describe "loaded comparison" do
    it "compares by identity first" do
      instance = loader.new(objects)

      expect(objects.first).to equal(objects.first)
      expect(instance.for(objects.first)).to eq([objects.first])

      expect { instance.for(object) }.to raise_error(N1Loader::NotLoaded)
    end

    it "falls back to equality comparison when no identity match" do
      equal_klass = Struct.new(:id)

      original = equal_klass.new(1)
      equal_copy = equal_klass.new(1)

      custom_loader = Class.new(N1Loader::Loader) do
        def perform(elements)
          elements.each { |element| fulfill(element, [element]) }
        end
      end

      instance = custom_loader.new([original])

      expect(original).not_to equal(equal_copy)
      expect(instance.for(original)).to eq([original])
      expect(instance.for(equal_copy)).to eq([original])
    end
  end

  context "when fulfill was not used" do
    it "throws error" do
      expect { object.missing_fulfill }
        .to raise_error(N1Loader::NotFilled, "Nothing was preloaded, perhaps you forgot to use fulfill method")
    end
  end

  describe "question mark support" do
    it "works" do
      expect { object.with_question_mark?(something: "something") }.not_to raise_error
      expect(object.with_question_mark?(something: "something")).to eq([object, "something"])
    end
  end

  describe "clear cache" do
    it "works" do
      expect { object.inline }.to change(klass, :count).by(1)
      expect { object.inline }.not_to change(klass, :count)
      object.n1_clear_cache
      expect { object.inline }.to change(klass, :count).by(1)
      expect { object.inline }.not_to change(klass, :count)
    end

    context "with parent loader" do
      let(:object) { child_klass.new }

      it "works" do
        expect { object.inline }.to change(child_klass, :count).by(1)
        expect { object.child_something }.to change(child_klass, :count).by(1)
        expect { object.inline }.not_to change(child_klass, :count)
        expect { object.child_something }.not_to change(child_klass, :count)

        object.n1_clear_cache

        expect { object.inline }.to change(child_klass, :count).by(1)
        expect { object.child_something }.to change(child_klass, :count).by(1)
        expect { object.inline }.not_to change(child_klass, :count)
        expect { object.child_something }.not_to change(child_klass, :count)
      end
    end
  end

  describe "arguments support" do
    it "has to receive all arguments" do
      expect { object.with_arguments }.to raise_error(N1Loader::MissingArgument)
      expect { object.with_arguments(something: "something") }.to raise_error(N1Loader::MissingArgument)
      expect { object.with_arguments("something") }.to raise_error(ArgumentError)

      expect(object.with_arguments(something: "something",
                                   anything: "anything")).to eq([object,
                                                                 "something", "anything"])
    end

    it "supports optional arguments" do
      expect { object.with_optional_argument }
        .to raise_error(N1Loader::MissingArgument, "Loader requires [:anything] arguments but they are missing")
      expect(object.with_optional_argument(anything: 2)).to eq([object, nil, 2])
      expect(object.with_optional_argument(something: 1, anything: 2)).to eq([object, 1, 2])
      expect { object.with_optional_argument(tmp: 1, anything: 2) }
        .to raise_error(N1Loader::InvalidArgument, "Loader doesn't define tmp argument")
    end

    it "supports default arguments" do
      expect { object.with_default_argument }
        .to raise_error(N1Loader::MissingArgument, "Loader requires [:anything] arguments but they are missing")
      expect(object.with_default_argument(anything: 2)).to eq([object, [], 2])
      expect(object.with_default_argument(something: 1, anything: 2)).to eq([object, 1, 2])
      expect { object.with_default_argument(tmp: 1, anything: 2) }
        .to raise_error(N1Loader::InvalidArgument, "Loader doesn't define tmp argument")
    end

    it "can have custom arguments key" do
      # The following two has the same result for custom key, so we only do one perform
      expect { object.with_custom_arguments_key(something: 1, anything: 2) }.to change(klass, :count).by(1)
      expect { object.with_custom_arguments_key(something: 2, anything: 1) }.not_to change(klass, :count)

      expect { object.with_custom_arguments_key(something: 2, anything: 3) }.to change(klass, :count).by(1)
    end

    it "supports named arguments" do
      expect do
        object.with_custom_arguments_key
      end.to raise_error(N1Loader::MissingArgument,
                         "Loader requires [:something, :anything] arguments but they are missing")
      expect do
        object.with_custom_arguments_key(something: "something")
      end.to raise_error(N1Loader::MissingArgument,
                         "Loader requires [:anything] arguments but they are missing")

      expect(object.with_custom_arguments_key(something: "something",
                                              anything: "anything")).to eq([
                                                                             object, "something", "anything"
                                                                           ])
    end

    it "supports falsey argument values" do
      expect(object.with_default_argument(anything: 2)).to eq([object, [], 2])                      # default value
      expect(object.with_default_argument(something: false, anything: 2)).to eq([object, false, 2]) # false
      expect(object.with_default_argument(something: nil, anything: 2)).to eq([object, nil, 2])     # nil
    end

    it "works with preloading" do
      N1Loader::Preloader.new(objects).preload(:with_arguments)

      expect do
        objects.each do |object|
          expect(object.with_arguments(something: "something",
                                       anything: "anything")).to eq([object,
                                                                     "something", "anything"])
        end
      end.to change(klass, :count).by(1)
    end

    it "caches based on arguments" do
      N1Loader::Preloader.new(objects).preload(:with_arguments, :with_default_argument)

      expect do
        objects.each { |object| object.with_arguments(something: "something", anything: "anything") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments(something: "something2", anything: "anything") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments(something: "something", anything: "anything2") }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_arguments(something: "something", anything: "anything") }
      end.not_to change(klass, :count)

      expect do
        objects.each { |object| object.with_default_argument(something: false, anything: nil) }
      end.to change(klass, :count).by(1)

      expect do
        objects.each { |object| object.with_default_argument(something: false, anything: nil) }
      end.not_to change(klass, :count)
    end

    it "supports reloading" do
      expect do
        object.with_arguments(something: "something", anything: "anything")
      end.to change(klass, :count).by(1)

      expect do
        object.with_arguments(something: "something", anything: "anything", reload: true)
      end.to change(klass, :count).by(1)

      expect do
        object.with_arguments(something: "something", anything: "anything")
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

  describe "n1_bind_to" do
    it "returns correct data for each bound object" do
      objects.each { |obj| obj.n1_bind_to(objects) }

      expect(objects.first.inline).to eq([objects.first])
      expect(objects.last.inline).to eq([objects.last])
    end

    it "loads all bound objects in a single batch" do
      objects.each { |obj| obj.n1_bind_to(objects) }

      expect { objects.map(&:inline) }.to change(klass, :count).by(1)
    end

    it "caches the result after the first load" do
      objects.each { |obj| obj.n1_bind_to(objects) }

      expect { objects.map(&:inline) }.to change(klass, :count).by(1)
      expect { objects.map(&:inline) }.not_to change(klass, :count)
    end

    it "lazily loads when the first object is accessed" do
      objects.each { |obj| obj.n1_bind_to(objects) }

      expect { objects.first.inline }.to change(klass, :count).by(1)
      expect { objects.last.inline }.not_to change(klass, :count)
    end
  end

  describe "automatic context binding" do
    let(:nested_klass) do
      Class.new do
        include N1Loader::Loadable

        class << self
          def perform!(loader)
            @counts ||= {}
            @counts[loader] = (@counts[loader] || 0) + 1
          end

          def count(loader)
            @counts&.fetch(loader, 0) || 0
          end
        end

        n1_optimized :first_loader do |elements|
          elements.first.class.perform!(:first_loader)
          elements.each { |el| fulfill(el, el) }
        end

        n1_optimized :second_loader do |elements|
          elements.first.class.perform!(:second_loader)
          elements.each { |el| fulfill(el, el) }
        end
      end
    end

    let(:nested_objects) { [nested_klass.new, nested_klass.new] }

    it "automatically sets shared context when loaded through N1Loader" do
      N1Loader::Preloader.new(nested_objects).preload(:first_loader)

      # Accessing first_loader triggers perform([obj1, obj2]),
      # which automatically calls n1_bind_to on both objects
      nested_objects.first.first_loader

      # Both objects are now auto-bound; second_loader should batch in one perform call
      expect { nested_objects.map(&:second_loader) }.to change { nested_klass.count(:second_loader) }.by(1)
    end

    it "auto-binds so second access on sibling does not trigger another load" do
      N1Loader::Preloader.new(nested_objects).preload(:first_loader)

      nested_objects.first.first_loader

      nested_objects.first.second_loader
      expect { nested_objects.last.second_loader }.not_to change { nested_klass.count(:second_loader) } # rubocop:disable Lint/AmbiguousBlockAssociation
    end

    it "auto-binds single element to a collection containing only itself" do
      single = nested_klass.new
      N1Loader::Preloader.new([single]).preload(:first_loader)

      single.first_loader

      # Accessing second_loader on the single element should still work correctly
      expect { single.second_loader }.to change { nested_klass.count(:second_loader) }.by(1)
      expect { single.second_loader }.not_to change { nested_klass.count(:second_loader) } # rubocop:disable Lint/AmbiguousBlockAssociation
    end
  end
end
