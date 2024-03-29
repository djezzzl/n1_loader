# frozen_string_literal: true

RSpec.describe "N1Loader AR Lazy Preload integration" do
  require_relative "../lib/n1_loader/ar_lazy_preload"

  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.include(ArLazyPreload::Base)

    ActiveRecord::Relation.prepend(ArLazyPreload::Relation)
    ActiveRecord::AssociationRelation.prepend(ArLazyPreload::AssociationRelation)
    ActiveRecord::Relation::Merger.prepend(ArLazyPreload::Merger)

    [
      ActiveRecord::Associations::CollectionAssociation,
      ActiveRecord::Associations::Association
    ].each { |klass| klass.prepend(ArLazyPreload::Association) }

    ActiveRecord::Associations::CollectionAssociation.prepend(ArLazyPreload::CollectionAssociation)
    ActiveRecord::Associations::CollectionProxy.prepend(ArLazyPreload::CollectionProxy)

    ArLazyPreload::Preloader.patch_for_rails_7! if ActiveRecord::VERSION::MAJOR >= 7
  end

  before do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table, force: :cascade)
    end
    ActiveRecord::Schema.verbose = false

    ActiveRecord::Schema.define(version: 1) do
      create_table(:entities)
      create_table(:companies) do |t|
        t.belongs_to :entity
      end
    end

    stub_const("Entity", Class.new(ActiveRecord::Base) do
      self.table_name = :entities

      has_one :company, class_name: "Company"

      class << self
        def name
          "Entity"
        end

        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end

      n1_optimized :data do
        def perform(elements)
          elements.first.class.perform!

          elements.each { |element| fulfill(element, [element]) }
        end
      end

      n1_optimized :with_arguments do
        argument :something

        def perform(elements)
          Entity.perform!

          elements.each { |element| fulfill(element, [element, something]) }
        end
      end
    end)

    stub_const("Company", Class.new(ActiveRecord::Base) do
      self.table_name = :companies

      belongs_to :entity, class_name: "Entity"

      class << self
        def name
          "Company"
        end

        def perform!
          @count = count + 1
        end

        def count
          @count || 0
        end
      end

      n1_optimized :data do
        def perform(elements)
          elements.first.class.perform!

          hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
          elements.each { |element| fulfill(element, hash[element.entity_id]) }
        end
      end

      n1_optimized :with_arguments do
        argument :something

        def perform(elements)
          Company.perform!

          hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
          elements.each { |element| fulfill(element, [hash[element.entity_id], something]) }
        end
      end

      n1_optimized :with_question_mark? do
        argument :something

        def perform(elements)
          Entity.perform!

          elements.each { |element| fulfill(element, [element, something]) }
        end
      end
    end)
  end

  before do
    Company.create!(entity: Entity.create!)
    Company.create!(entity: Entity.create!)
  end

  describe "question mark support" do
    it "works" do
      expect do
        Company.preload_associations_lazily.each do |company|
          expect(company.with_question_mark?(something: "something")).to eq([company, "something"])
        end
      end.not_to raise_error
    end
  end

  it "works" do
    expect do
      Company.preload_associations_lazily.all.map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 2)
      .and change(Company, :count).by(1)

    expect do
      Entity.preload_associations_lazily.all.map(&:company).map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 2)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 3)
      .and change(Company, :count).by(1)

    expect do
      Company.preload_associations_lazily.all.map(&:data).map(&:company)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 2)
      .and make_database_queries(count: 3)
      .and change(Company, :count).by(1)

    expect do
      Company.lazy_preload(data: :company).map(&:data).map(&:company)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 2)
      .and make_database_queries(count: 3)
      .and change(Company, :count).by(1)
  end

  context "with arguments" do
    it "works" do
      expect do
        Company.preload_associations_lazily.all.each { |company| company.with_arguments(something: "something") }
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(count: 2)
        .and change(Company, :count).by(1)

      expect do
        Entity.preload_associations_lazily.all.each { |entity| entity.company.with_arguments(something: "something") }
      end
        .to make_database_queries(matching: /entities/, count: 2)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(count: 3)

      expect do
        Company.preload_associations_lazily.each do |company|
          company.with_arguments(something: "something").first.company
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 2)
        .and make_database_queries(count: 3)

      expect do
        Company.lazy_preload(with_arguments: :company).each do |company|
          company.with_arguments(something: "something").first.company
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 2)
        .and make_database_queries(count: 3)
    end
  end

  describe "isolated loaders" do
    let(:loader) do
      Class.new(N1Loader::Loader) do
        argument :something

        def perform(_companies)
          Company.perform!

          hash = Entity.where(id: elements.map(&:entity_id)).index_by(&:id)
          elements.each { |element| fulfill(element, [hash[element.entity_id], something]) }
        end
      end
    end

    it "works with ArLazyPreload context" do
      companies = Company.preload_associations_lazily.order(:id).to_a
      entity1 = Entity.first
      entity2 = Entity.second

      loaded1 = loader.for(companies.first, something: "tmp")
      loaded2 = loader.for(companies.second, something: "tmp")

      expect(loaded1).to eq([entity1, "tmp"])
      expect(loaded2).to eq([entity2, "tmp"])
      expect(loaded1[0].lazy_preload_context)
        .to be_present
        .and eq(loaded2[0].lazy_preload_context)

      expect do
        companies.map do |company|
          loader.for(company, something: "something")
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(count: 1)
        .and change(Company, :count).by(1)

      expect do
        companies.each do |company|
          loader.for(company, something: "anything")
        end
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(count: 1)
        .and change(Company, :count).by(1)
    end

    context "when object does not have ArLazyPreload context" do
      it "raises an error" do
        expect do
          loader.for("string", something: "something")
        end.to raise_error(N1Loader::Loader::UnsupportedArLazyPreload)
        expect do
          loaded = loader.for(Company.first, something: "something")
          expect(loaded[0].lazy_preload_context).to be_present
        end.not_to raise_error
      end
    end
  end
end
