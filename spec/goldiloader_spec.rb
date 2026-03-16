# frozen_string_literal: true

RSpec.describe "N1Loader Goldiloader integration" do
  require_relative "../lib/n1_loader/goldiloader"

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
        Company.all.each do |company|
          expect(company.with_question_mark?(something: "something")).to eq([company, "something"])
        end
      end.not_to raise_error
    end
  end

  it "works" do
    expect do
      Company.all.map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 2)
      .and change(Company, :count).by(1)

    expect do
      Entity.all.map(&:company).map(&:data)
    end
      .to make_database_queries(matching: /entities/, count: 2)
      .and make_database_queries(matching: /companies/, count: 1)
      .and make_database_queries(count: 3)
      .and change(Company, :count).by(1)

    expect do
      Company.all.map(&:data).map(&:company)
    end
      .to make_database_queries(matching: /entities/, count: 1)
      .and make_database_queries(matching: /companies/, count: 2)
      .and make_database_queries(count: 3)
      .and change(Company, :count).by(1)
  end

  context "with arguments" do
    it "works" do
      expect do
        Company.all.each { |company| company.with_arguments(something: "something") }
      end
        .to make_database_queries(matching: /entities/, count: 1)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(count: 2)
        .and change(Company, :count).by(1)

      expect do
        Entity.all.each { |entity| entity.company.with_arguments(something: "something") }
      end
        .to make_database_queries(matching: /entities/, count: 2)
        .and make_database_queries(matching: /companies/, count: 1)
        .and make_database_queries(count: 3)

      expect do
        Company.all.each do |company|
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

    it "works with Goldiloader context" do
      companies = Company.order(:id).to_a
      entity1 = Entity.first
      entity2 = Entity.second

      loaded1 = loader.for(companies.first, something: "tmp")
      loaded2 = loader.for(companies.second, something: "tmp")

      expect(loaded1).to eq([entity1, "tmp"])
      expect(loaded2).to eq([entity2, "tmp"])
      expect(loaded1[0].auto_include_context)
        .to be_present
        .and eq(loaded2[0].auto_include_context)

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

    context "when object does not have Goldiloader context" do
      it "raises an error" do
        expect do
          loader.for("string", something: "something")
        end.to raise_error(N1Loader::Loader::UnsupportedGoldiloader)
        expect do
          loaded = loader.for(Company.first, something: "something")
          expect(loaded[0].auto_include_context).to be_present
        end.not_to raise_error
      end
    end
  end
end
